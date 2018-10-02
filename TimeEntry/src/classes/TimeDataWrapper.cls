public with sharing class TimeDataWrapper {
    @AuraEnabled public List<Project__c> projList;
    @AuraEnabled public List<Task__c> taskList;
    @AuraEnabled public List<TimeWrapper> timeValList;
}