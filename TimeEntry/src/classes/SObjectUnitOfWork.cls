/**
 * Provides an implementation of the Enterprise Application Architecture Unit Of Work, as defined by
 * Martin Fowler
 *   http://martinfowler.com/eaaCatalog/unitOfWork.html
 **/
public with sharing class SObjectUnitOfWork {
    protected List<Schema.SObjectType> m_sObjectTypes = new List<Schema.SObjectType>();
    protected Map<String, List<SObject>> m_newListByType = new Map<String, List<SObject>>();
    protected Map<String, Map<Id, SObject>> m_dirtyMapByType = new Map<String, Map<Id, SObject>>();
    protected Map<String, Relationships> m_relationships = new Map<String, Relationships>();
    protected IDML m_dml;

    
    /**
     * Interface to describe DMLs
     **/

    public interface IDML
    {
        void dmlInsert(List<SObject> objList);
        void dmlUpdate(List<SObject> objList);
        void dmlDelete(List<SObject> objList);
    }

    public class SimpleDML implements IDML
    {
        public void dmlInsert(List<SObject> objList){
            insert objList;
        }
        public void dmlUpdate(List<SObject> objList){
            update objList;
        }
        public void dmlDelete(List<SObject> objList){
            delete objList;
        }
    }

    /**
     * Constructs a new UnitOfWork to support work against the given object list
     *
     * @param sObjectList A list of objects given in dependency order (least dependent first)
     */
    public SObjectUnitOfWork(List<Schema.SObjectType> sObjectTypes) {
        this(sObjectTypes,new SimpleDML());
    }


    public SObjectUnitOfWork(List<Schema.SObjectType> sObjectTypes, IDML dml) {
        m_sObjectTypes = sObjectTypes.clone();
        for(Schema.SObjectType sObjectType : m_sObjectTypes) {
            // register the type
            handleRegisterType(sObjectType);
        }
        m_dml = dml;
    }

    /**
     * Registers the type to be used for DML operations
     * @param sObjectType - The type to register
     **/
    private void handleRegisterType (Schema.SObjectType sObjectType) {
        // add type to dml operation tracking
        m_newListByType.put(sObjectType.getDescribe().getName(), new List<SObject>());
        m_dirtyMapByType.put(sObjectType.getDescribe().getName(), new Map<Id, SObject>());
        m_relationships.put(sObjectType.getDescribe().getName(), new Relationships());
    }

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called
     * @param record A newly created SObject instance to be inserted during commitWork
     **/
    public void registerNew(SObject record) {
        registerNew(record, null, null);
    }

    /**
     * Register a list of newly created SObject instances to be inserted when commitWork is called
     * @param records A list of newly created SObject instances to be inserted during commitWork
     **/
    public void registerNew(List<SObject> records) {
        for(SObject record : records) {
            registerNew(record, null, null);
        }
    }

    /**
     * Register a newly created SObject instance to be inserted when commitWork is called,
     * you may also provide a reference to the parent record instance (should also be registered
     * as new separatly)
     *
     * @param record A newly created SObject instance to be inserted during commitWork
     * @param relatedToParentField A SObjectField reference to the child field that associates the
     * child record with its parent
     * @param relatedToParentRecord A SObject instance of the parent record (should also be
     * registered as new separatly)
     **/
    public void registerNew(SObject record, Schema.sObjectField relatedToParentField,
                            SObject relatedToParentRecord) {
        if(record.Id != null)
            throw new UnitOfWorkException('Only new records can be registered as new');
        String sObjectType = record.getSObjectType().getDescribe().getName();
        if(!m_newListByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this'+
                                        ' unit of work', new String[] { sObjectType }));
        m_newListByType.get(sObjectType).add(record);
        if(relatedToParentRecord!=null && relatedToParentField!=null)
            registerRelationship(record, relatedToParentField, relatedToParentRecord);
    }

    /**
     * Register a relationship between two records that have yet to be inserted to the database.
     * This information will be used during the commitWork phase to make the references only when
     * related records have been inserted to the database.
     *
     * @param record An existing or newly created record
     * @param relatedToField A SObjectField referene to the lookup field that relates the two
     * records together
     * @param relatedTo A SOBject instance (yet to be commited to the database)
     */
    public void registerRelationship(SObject record, Schema.sObjectField relatedToField,
                                    SObject relatedTo) {
        String sObjectType = record.getSObjectType().getDescribe().getName();
        if(!m_newListByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this'+
                                        ' unit of work', new String[] { sObjectType }));
        m_relationships.get(sObjectType).add(record, relatedToField, relatedTo);
    }

    /**
     * Register an existing record to be updated during the commitWork method
     * @param record An existing record
     **/
    public void registerDirty(SObject record) {
        registerDirty(record, new List<SObjectField>());
    }

    public void registerDirty(SObject record, List<SObjectField> dirtyFields) {
        if(record.Id == null)
            throw new UnitOfWorkException('New records cannot be registered as dirty');
        String sObjectType = record.getSObjectType().getDescribe().getName();
        if(!m_dirtyMapByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this'+
                                                ' unit of work', new String[] { sObjectType }));

        // If record isn't registered as dirty, or no dirty fields to drive a merge
        if (!m_dirtyMapByType.get(sObjectType).containsKey(record.Id) || dirtyFields.isEmpty()) {
            // Register the record as dirty
            m_dirtyMapByType.get(sObjectType).put(record.Id, record);
        } else {
            // Update the registered record's fields
            SObject registeredRecord = m_dirtyMapByType.get(sObjectType).get(record.Id);

            for (SObjectField dirtyField : dirtyFields) {
                registeredRecord.put(dirtyField, record.get(dirtyField));
            }

            m_dirtyMapByType.get(sObjectType).put(record.Id, registeredRecord);
        }
    }

    /**
     * Register an existing record to be updated when commitWork is called, you may also provide
     * a reference to the parent record instance (should also be registered as new separatly)
     *
     * @param record A newly created SObject instance to be inserted during commitWork
     * @param relatedToParentField A SObjectField reference to the child field that associates the
     * child record with its parent
     * @param relatedToParentRecord A SObject instance of the parent record (should also be
     * registered as new separatly)
     **/
    public void registerDirty(SObject record, Schema.sObjectField relatedToParentField,
                                SObject relatedToParentRecord) {
        if(record.Id == null)
            throw new UnitOfWorkException('New records cannot be registered as dirty');
        String sObjectType = record.getSObjectType().getDescribe().getName();
        if(!m_dirtyMapByType.containsKey(sObjectType))
            throw new UnitOfWorkException(String.format('SObject type {0} is not supported by this' +
                                    ' unit of work', new String[] { sObjectType }));
        m_dirtyMapByType.get(sObjectType).put(record.Id, record);
        if(relatedToParentRecord!=null && relatedToParentField!=null)
            registerRelationship(record, relatedToParentField, relatedToParentRecord);
    }

    /**
     * Register a list of existing records to be updated during the commitWork method
     * @param records A list of existing records
     **/
    public void registerDirty (List<SObject> records) {
        for(SObject record : records) {
            this.registerDirty(record);
        }
    }

    /**
     * Takes all the work that has been registered with the UnitOfWork and commits it to the
     * database
     **/
    public void commitWork() {
        // Wrap the work in its own transaction
        Savepoint sp = Database.setSavePoint();
        try {
            // Insert by type
            for(Schema.SObjectType sObjectType : m_sObjectTypes)
            {
                m_relationships.get(sObjectType.getDescribe().getName()).resolve();
                m_dml.dmlInsert(m_newListByType.get(sObjectType.getDescribe().getName()));
            }
            // Update by type
            for(Schema.SObjectType sObjectType : m_sObjectTypes)
                m_dml.dmlUpdate(m_dirtyMapByType.get(sObjectType.getDescribe().getName()).values());
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            // Throw exception on to caller
            throw e;
        }
    }

    // Interface
    private interface IRelationship {
        void resolve();
    }

    private class Relationships {
        private List<IRelationship> m_relationships = new List<IRelationship>();

        public void resolve() {
            // Resolve relationships
            for(IRelationship relationship : m_relationships) {
                //relationship.Record.put(relationship.RelatedToField, relationship.RelatedTo.Id);
                relationship.resolve();
            }
        }

        public void add(SObject record, Schema.sObjectField relatedToField, SObject relatedTo) {
            // Relationship to resolve
            Relationship relationship = new Relationship();
            relationship.Record = record;
            relationship.RelatedToField = relatedToField;
            relationship.RelatedTo = relatedTo;
            m_relationships.add(relationship);
        }
    }

    private class Relationship implements IRelationship {
        public SObject Record;
        public Schema.sObjectField RelatedToField;
        public SObject RelatedTo;

        public void resolve() {
            this.Record.put( this.RelatedToField, this.RelatedTo.Id);
        }
    }

    /**
     * UnitOfWork Exception
     **/
    public class UnitOfWorkException extends Exception {}
}