public class TimeWrapper {
    @AuraEnabled public Time_Entry__c timeEntry;
    @AuraEnabled public String currTime;
    @AuraEnabled public Boolean isPause;
   // @AuraEnabled public Boolean isRunningTimer;
    public TimeWrapper (Time_Entry__c pTimeEntry, String pCurTime, 
                             Boolean pIsPause/*, Boolean pIsRunningTimer */) {
        this.timeEntry = pTimeEntry;
        this.currTime = pCurTime;
        this.isPause = pIsPause;
        //this.isRunningTimer = pIsRunningTimer;
    }
}