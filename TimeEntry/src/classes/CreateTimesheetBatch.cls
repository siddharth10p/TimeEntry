/**
 * Decription: This is a batch class that runs every sunday night and create a timesheet
 * record for the current week.
 *
 * Created Date: 19-Sept-2018
 * Created By: Siddharth Pandit
 **/
global with sharing class CreateTimesheetBatch implements Database.Batchable<sObject>,
                                                            Schedulable{

    // No data to fetch
    global Database.QueryLocator start(Database.BatchableContext BC){
      return Database.getQueryLocator([SELECT Id, Name FROM User]);
   }

   global void execute(Database.BatchableContext BC, List<sObject> scope){
       List<Timesheet__c> timeSheetListToInsert = new List<Timesheet__c> ();
       for (User aUser : (List<User>) scope) {
            Timesheet__c timeSheet = new Timesheet__c ();
            timeSheet.Name = aUser.Name + ' - ' + 
                            TimerUtil.monthName.get (Date.today ().month());
            timeSheet.Week_Start_Date__c = Date.today ().addDays (1); // Set as Monday
            timeSheet.Week_End_Date__c = Date.today ().addDays (7); // Set as Sunday
            timeSheet.Developer__c = aUser.Id;
            timeSheetListToInsert.add (timeSheet);
       }// End for

        if (!timeSheetListToInsert.isEmpty ())
            insert timeSheetListToInsert;
    } // End method

    global void finish(Database.BatchableContext BC){
    }

    global void execute(SchedulableContext SC){
        CreateTimesheetBatch createTimeSheet = new CreateTimesheetBatch();
        ID batchProcessId = Database.executeBatch(createTimeSheet, 200);
    }
}