public class TimerControllerChild {
    @AuraEnabled public Time_Entry__c timeEntry;
    @AuraEnabled public String currTime;
    @AuraEnabled public Boolean isPause;
    public TimerControllerChild (Time_Entry__c pTimeEntry, String pCurTime, 
                             Boolean pIsPause) {
        this.timeEntry = pTimeEntry;
        this.currTime = pCurTime;
        this.isPause = pIsPause;
    }
}