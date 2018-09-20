/**
 * Description: This is a controller class that updates time field on
 * the time entry record
 *
 * Created Date:10-Sept-2018
 * Created By: Siddharth Pandit
 **/
public with sharing class TimerController {
    @AuraEnabled
    public static String createTimeEntry (String pProjId, String pTaskId) {
         if (pProjId == null || pTaskId == null)
             return null;
            Time_Entry__c timeEntry = new Time_Entry__c ();
            timeEntry.Project__c = pProjId;
            timeEntry.Task__c = pTaskId;
            timeEntry.Start_Time__c = Datetime.now();
            timeEntry.Timesheet__c = retrieveTimeSheetId (timeEntry);
            insert timeEntry;
        	System.debug ('timeEntry ==> '+ timeEntry);
        return timeEntry.Id;
    }
    
    public static String retrieveTimeSheetId (Time_Entry__c pTimeEntry) {
        List<Timesheet__c> timeSheetList = [SELECT Id FROM Timesheet__c
                                            WHERE Approve__c = false
                                            AND Week_Start_Date__c <= TODAY
                                            AND Week_End_Date__c >= TODAY
                                            AND Developer__c =: UserInfo.getUserId ()
                                            ORDER BY CreatedDate DESC
                                            LIMIT 1];
        if (!timeSheetList.isEmpty ())
            return timeSheetList.get (0).Id;
        else return null;
    }

    @AuraEnabled
    public static String fetchTaskId (String pProjectId) {
        List<Time_Entry__c> timeEntry = [SELECT Id, Project__c, Task__c
                                            FROM Time_Entry__c
                                            WHERE Project__c =: pProjectId
                                            AND End_Time__c = null
                                            AND Start_Time__c <> null
                                            AND Approve__c = false
                                            ORDER BY CreatedDate DESC];
        if (!timeEntry.isEmpty ())
            return timeEntry.get (0).Task__c;
            return null;
    }

    @AuraEnabled
    public static void updateTime (String pTime, String pRecId, String pNote) {
            System.debug ('pTime ==> ' + pTime);
            System.debug ('pRecId ==> ' + pRecId);
            System.debug ('pNote ==> ' + pNote);
        if (String.isNotBlank (pTime) && String.isNotBlank (pRecId)) {
            List<Time_Entry__c> timeEntryList = [SELECT Time__c, Notes__c
                                                FROM Time_Entry__c
                                                WHERE Id =: pRecId
                                                LIMIT 1];
            timeEntryList.get (0).Time__c = TimerUtil.convertTimeInDecimal (pTime);
            timeEntryList.get (0).Notes__c = pNote;
            timeEntryList.get (0).End_Time__c = Datetime.now ();
            System.debug ('timeEntryList ==> ' + timeEntryList);
            update timeEntryList;
        }
    }

   @AuraEnabled
    public static TimeEntryWrapper getTotalMins (String pProjId) {
        if (String.isBlank (pProjId)) 
            return null;
            // Fetch an active time entry related to the current project record
            List<Time_Entry__c> timeEntryList = [SELECT Id, Timer_Total_Mins__c,
                                                    Project__c, Task__c, Pause_Time__c
                                                FROM Time_Entry__c
                                                WHERE Project__c =: pProjId
                                                //AND Task__c =: pTaskId
                                                AND End_Time__c = null
                                                AND Start_Time__c <> null
                                                AND Approve__c = false
                                                ORDER BY CreatedDate DESC
                                                LIMIT 1];
        if (timeEntryList.isEmpty () || timeEntryList.get (0).Timer_Total_Mins__c == null)
            return null;
        Decimal totMins = timeEntryList.get (0).Timer_Total_Mins__c;
        Decimal hh = Math.floor (totMins /60);
        Integer mm = Math.mod (Integer.valueOf (totMins), 60);
        Boolean isPause = timeEntryList.get (0).Pause_Time__c == null ? false : true;
        TimeEntryWrapper wrp = new TimeEntryWrapper (Integer.valueOf (hh) + ', ' + mm,
                        timeEntryList.get (0).Project__c,
                        timeEntryList.get (0).Task__c, isPause,
                        timeEntryList.get (0).Id);
        System.debug ('wrp ==> '+ wrp);
        return wrp;
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
    public static void updatePauseTime (String pTimeEntryId) {
        System.debug ('pTimeEntryId ===> '+ pTimeEntryId);
        if (pTimeEntryId != null) {
            Time_Entry__c tEntry = [SELECT Id, Pause_Time__c,
                                        Project__c, Task__c
                                    FROM Time_Entry__c
                                    WHERE Id =: pTimeEntryId
                                    AND End_Time__c = null
                                    AND Start_Time__c <> null
                                    AND Approve__c = false
                                    LIMIT 1 ];
            tEntry.Pause_Time__c = Datetime.now ();
            update tEntry;
            System.debug ('tEntry ===> '+ tEntry);
        }
    }
    
    @AuraEnabled //  A method to update pause time when user clicks on pause
    public static void updateElapsedTime (String pTimeEntryId) {
        System.debug ('pTimeEntryId ===> '+ pTimeEntryId);
        if (pTimeEntryId != null) {
            Time_Entry__c tEntry = [SELECT Id, Pause_Time__c, Time_Elapsed__c,
                                        Start_Time__c, Project__c, Task__c
                                    FROM Time_Entry__c
                                    WHERE Id =: pTimeEntryId
                                    AND End_Time__c = null
                                    AND Start_Time__c <> null
                                    AND Pause_Time__c <> null
                                    AND Approve__c = false
                                    LIMIT 1 ];
            Datetime startTime = tEntry.Time_Elapsed__c == null ? tEntry.Start_Time__c : tEntry.Time_Elapsed__c;
            tEntry.Time_Elapsed__c = TimerUtil.retrieveElapsedDate (startTime, tEntry.Pause_Time__c);
            tEntry.Pause_Time__c = null;
            update tEntry;
            System.debug ('tEntry ===> '+ tEntry);
        }
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
    
    public class TimeEntryWrapper {
        @AuraEnabled public String currTime;
        @AuraEnabled public String projId;
        @AuraEnabled public String taskId;
        @AuraEnabled public Boolean isPause;
        @AuraEnabled public String timeEntryId;
        public TimeEntryWrapper (String pCurTime, String pProjId, String pTaskId,
                                 Boolean pIsPause, String pTimeEntryId) {
            this.currTime = pCurTime;
            this.projId = pProjId;
            this.taskId = pTaskId;
            this.isPause = pIsPause;
            this.timeEntryId = pTimeEntryId;
        }
    }
}