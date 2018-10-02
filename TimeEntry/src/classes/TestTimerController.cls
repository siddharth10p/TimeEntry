/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class TestTimerController {

    static testMethod void coverControllerCode() {
        TimerUtil.setTestData ();
            Time_Entry__c timeEntry = [SELECT Id FROM Time_Entry__c LIMIT 1];
            Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
            Task__c task = [SELECT Id FROM Task__c LIMIT 1];
        Test.startTest ();
            TimerController timeController = new TimerController ();
            TimerController.createTimeEntry (proj.Id, task.Id, 'Test notes');
            TimerController.updateElapsedTime (timeEntry.Id);
            TimerController.retrieveTimeObj (proj.Id);
            TimerController.updatePauseTime (timeEntry.Id, 'This is test notes');
            TimerController.fetchTasks (proj.Id);
            TimerController.fetchAllProjects (null);
            TimerController.fetchAllProjects (timeEntry.Id);
            TimerController.updateTime ('05:00', timeEntry.Id, 'Test notes');
        Test.stopTest ();
    }

    // A method that covers TimeEntryApproval code
    static testMethod void coverTimeEntryApprovalCode () {
        TimerUtil.setTestData ();
        Timesheet__c  timeSheet = [SELECT Id, Approve__c FROM Timesheet__c LIMIT 1];
        Approval.lockResult lrList = Approval.lock (timeSheet , false);
        Test.startTest ();
            TimeEntryApproval.unlockTimeEntries (timeSheet.Id);
        Test.stopTest ();
    }
}