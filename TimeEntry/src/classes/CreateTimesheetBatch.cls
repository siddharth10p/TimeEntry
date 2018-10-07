/**
 * Decription: This is a batch class that runs every sunday night and create a timesheet
 * record for the current week.
 *
 * Created Date: 19-Sept-2018
 * Created By: Siddharth Pandit
 **/
global with sharing class CreateTimesheetBatch implements Database.Batchable<sObject>,
                                                            Schedulable{
    SObjectUnitOfWork uow = new SObjectUnitOfWork(
        new Schema.SObjectType[] { Timesheet__c.SObjectType }
    );

    // No data to fetch
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id, Name FROM User]);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
       for (User aUser : (List<User>) scope) {
            Timesheet__c timeSheet = new Timesheet__c ();
            timeSheet.Name = aUser.Name + ' - ' + 
                            TimerUtil.monthName.get (Date.today ().month());
            timeSheet.Week_Start_Date__c = Date.today ().addDays (1); // Set as Monday
            timeSheet.Week_End_Date__c = Date.today ().addDays (7); // Set as Sunday
            timeSheet.Developer__c = aUser.Id;
            uow.registerNew (timeSheet, Timesheet__c.Developer__c, aUser);
       }// End for

        uow.commitWork ();
    } // End method

    global void finish(Database.BatchableContext BC){
    }

    global void execute(SchedulableContext SC){
        CreateTimesheetBatch createTimeSheet = new CreateTimesheetBatch();
        ID batchProcessId = Database.executeBatch(createTimeSheet, 200);
    }
}