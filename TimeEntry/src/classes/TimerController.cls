/**
 * Description: This is a controller class that updates time field on
 * the time entry record
 *
 * Created Date:10-Sept-2018
 * Created By: Siddharth Pandit
 **/
public without sharing class TimerController {
    @AuraEnabled
    public static TimeWrapper createTimeEntry (String pProjId, String pTaskId, String pNotes) {
         if (pProjId == null || pTaskId == null)
             return null;
            SObjectUnitOfWork uow = new SObjectUnitOfWork ( new Schema.SObjectType[] {
                                    Time_Entry__c.SObjectType });
            Time_Entry__c timeEntry = new Time_Entry__c ();
            timeEntry.Project__c = pProjId;
            timeEntry.Task__c = pTaskId;
            timeEntry.Notes__c = pNotes;
            timeEntry.Start_Time__c = Datetime.now();
            uow.registerNew (timeEntry, Time_Entry__c.Timesheet__c, retrieveTimeSheet (timeEntry));
            uow.commitWork ();
            System.debug ('timeEntry ==> '+ timeEntry);
        return TimerUtil.createWrpInstance (timeEntry);
    }

    public static Timesheet__c retrieveTimeSheet (Time_Entry__c pTimeEntry) {
        List<Timesheet__c> timeSheetList = [SELECT Id FROM Timesheet__c
                                            WHERE Approve__c = false
                                            AND Week_Start_Date__c <= TODAY
                                            AND Week_End_Date__c >= TODAY
                                            AND Developer__c =: UserInfo.getUserId ()
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1];
        if (!timeSheetList.isEmpty ())
            return timeSheetList.get (0);
        else return null;
    }

    @AuraEnabled
    public static void updateTime (String pTime, String pRecId, String pNote) {
            System.debug ('pTime ==> ' + pTime);
            System.debug ('pRecId ==> ' + pRecId);
            System.debug ('pNote ==> ' + pNote);
        if (String.isNotBlank (pTime) && String.isNotBlank (pRecId)) {
            SObjectUnitOfWork uow = new SObjectUnitOfWork ( new Schema.SObjectType[] {
                                    Time_Entry__c.SObjectType });
            List<Time_Entry__c> timeEntryList = [SELECT Id, Time__c, Notes__c
                                                FROM Time_Entry__c
                                                WHERE Id =: pRecId
                                                LIMIT 1];
            timeEntryList.get (0).Time__c = TimerUtil.convertTimeInDecimal (pTime);
            timeEntryList.get (0).Notes__c = pNote;
            timeEntryList.get (0).End_Time__c = Datetime.now ();
            uow.registerDirty (timeEntryList);
            uow.commitWork ();
            System.debug ('timeEntryList ==> ' + timeEntryList);
        }
    }

   @AuraEnabled
    public static TimeDataWrapper retrieveTimeObj (String pProjId) {
        TimeDataWrapper timeWrp = new TimeDataWrapper ();
        Set<Id> timesheetIdSet = new Set<Id> ();
        for (Timesheet__c timesheet : [SELECT Id FROM Timesheet__c
                                        WHERE Approve__c = false
                                        AND Week_Start_Date__c <= TODAY
                                        AND Week_End_Date__c >= TODAY
                                        AND Developer__c =: UserInfo.getUserId ()]) {
            timesheetIdSet.add (timesheet.Id);
        }
            List<TimeWrapper> timeListToReturn = new List<TimeWrapper> ();
            // Fetch an active time entry related to the current project record
            String queryStr = ' SELECT Id, Name, Timer_Total_Mins__c, Notes__c, Project__c, Task__c,'+
                              ' Project__r.Name, Task__r.Name, Pause_Time__c FROM Time_Entry__c';
                  queryStr += ' WHERE Start_Time__c <> null AND End_Time__c = null' + 
                                ' AND Approve__c = false';
                  queryStr += String.isBlank (pProjId)? '' :' AND Project__c =: pProjId';
                  queryStr += ' AND Timesheet__c IN : timesheetIdSet'+
                            ' ORDER BY LastModifiedDate DESC';
            System.debug ('queryStr ==> ' + queryStr);
            for (Time_Entry__c timeEntry : Database.query (queryStr)) {
                Boolean isPause = timeEntry.Pause_Time__c == null ? false : true;
                if (!isPause && !timeListToReturn.isEmpty()) {
                    timeListToReturn.add (0, TimerUtil.createWrpInstance (timeEntry));
                } else {
                    timeListToReturn.add ( TimerUtil.createWrpInstance (timeEntry));
                }
            }
            timeWrp.timeValList = timeListToReturn;
            timeWrp.projList = fetchAllProjects (null);
            String projId = timeListToReturn.isEmpty () ? pProjId :
                            timeListToReturn.get (0).timeEntry.Project__c;
            timeWrp.taskList = fetchTasks (projId);
        System.debug ('timeListToReturn ==> '+ timeListToReturn);
        System.debug ('timeWrp ==> '+ timeWrp);
        return timeWrp;
    } // End method

    @AuraEnabled
    public static List<Task__c> fetchTasks (String pProjectId) {
        if (String.isBlank (pProjectId)) 
            return null;
        return [SELECT Id, Name, Default_Hourly_Rate__c, Is_Billable__c,
                                    Description__c, Project__c
                            FROM Task__c
                            WHERE Project__c =: pProjectId];
    }
    
    @AuraEnabled //  A method to update pause time when user clicks on pause
    public static void updatePauseTime (String pTimeEntryId, String pNotes) {
        System.debug ('pTimeEntryId ===> '+ pTimeEntryId);
        if (pTimeEntryId != null) {
            SObjectUnitOfWork uow = new SObjectUnitOfWork ( new Schema.SObjectType[] {
                                    Time_Entry__c.SObjectType });
            Time_Entry__c tEntry = [SELECT Id, Pause_Time__c, Notes__c,
                                        Project__c, Task__c
                                    FROM Time_Entry__c
                                    WHERE Id =: pTimeEntryId
                                    AND End_Time__c = null
                                    AND Start_Time__c <> null
                                    AND Approve__c = false
                                    LIMIT 1 ];
            tEntry.Pause_Time__c = Datetime.now ();
            tEntry.Notes__c = pNotes;
            uow.registerDirty (tEntry);
            uow.commitWork ();
            System.debug ('tEntry ===> '+ tEntry);
        }
    }

    @AuraEnabled //  A method to update pause time when user clicks on pause
    public static TimeWrapper updateElapsedTime (String pTimeEntryId) {
        System.debug ('pTimeEntryId ===> '+ pTimeEntryId);
        if (pTimeEntryId == null) return null;
            SObjectUnitOfWork uow = new SObjectUnitOfWork ( new Schema.SObjectType[] {
                                    Time_Entry__c.SObjectType });
            Time_Entry__c tEntry = [SELECT Id, Pause_Time__c, Time_Elapsed__c, Timer_Total_Mins__c,
                                        Notes__c, Project__c, Task__c, Project__r.Name, 
                                        Task__r.Name, Start_Time__c
                                    FROM Time_Entry__c
                                    WHERE Id =: pTimeEntryId
                                    AND End_Time__c = null
                                    AND Start_Time__c <> null
                                    AND Pause_Time__c <> null
                                    AND Approve__c = false
                                    LIMIT 1 ];
            Datetime startTime = tEntry.Time_Elapsed__c == null ? tEntry.Start_Time__c :
                                tEntry.Time_Elapsed__c;
            tEntry.Time_Elapsed__c = TimerUtil.retrieveElapsedTime (startTime, tEntry.Pause_Time__c);
            tEntry.Pause_Time__c = null;
            uow.registerDirty (tEntry);
            uow.commitWork ();
            System.debug ('tEntry ===> '+ tEntry);
        return TimerUtil.createWrpInstance (tEntry);
    }

    @AuraEnabled
    public static List<Project__c> fetchAllProjects (String pProjId) {
        if (String.isBlank (pProjId)) {
            return [SELECT Id, Name, Project_expenses__c, Budget__c
                    FROM Project__c];
        }
        return [SELECT Id, Name, Project_expenses__c, Budget__c
                FROM Project__c
                WHERE Id =: pProjId];
    }
}