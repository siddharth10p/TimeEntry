public without sharing class TimeEntryApproval {

    @AuraEnabled
    public static void unlockTimeEntries (String pTimesheetId) {
        // Query the timesheet to unlock
        Timesheet__c  timeSheet = [SELECT Id, Approve__c FROM Timesheet__c WHERE Id =: pTimesheetId];
        // Unlock the timesheet
        Approval.UnlockResult lrList = Approval.unlock (timeSheet , false);
        if (lrList.isSuccess()) {
            // Operation was successful, so get the ID of the record that was processed
            System.debug('Successfully unlocked timesheet with ID: ' + lrList.getId());
        } else {
            // Operation failed, so get all errors
            for(Database.Error err : lrList.getErrors()) {
                System.debug('The following error has occurred.');
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Account fields that affected this error: ' + err.getFields());
            }
        }
    }
}