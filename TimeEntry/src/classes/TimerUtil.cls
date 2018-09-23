/**
 * Description: This class contains all utility methods for timer
 * component
 *
 * Created By: Siddharth Pandit
 * Created Date: 13-Sept-2018
 **/
public with sharing class TimerUtil {

    // A method that converts the time from string to decimal
    public static Decimal convertTimeInDecimal (String pLoggedTime) {
        List<String> strList = pLoggedTime.split (':');
        String hh, mm ;
        hh = strList.get (0);
        Integer min = Integer.valueOf (strList.get (1));
        if (min > 45)
            mm = '75';
        else if (min > 30)
            mm = '50';
        else if (min > 15)
            mm = '25';
        else 
            mm = '00';
        return Decimal.valueOf (hh+'.'+mm);
    }

    public static Datetime convertDateTimeGMT (Datetime pDateTime) {
        return Datetime.newInstanceGMT(pDateTime.year(), pDateTime.month(),
                    pDateTime.day(), pDateTime.hour(), pDateTime.minute(), pDateTime.second());
    }

    public static Datetime retrieveElapsedTime (Datetime pStartTime, Datetime pPauseTime) {
        if (pStartTime == null || pPauseTime == null)
            return null;
        Datetime pauseTimeGMT = convertDateTimeGMT (pPauseTime);
        Datetime startTimeGMT = convertDateTimeGMT (pStartTime);
        System.debug ('localTime ==> ' + pauseTimeGMT.getTime());
        System.debug ('localTime ==> ' + Datetime.now ().getTime());
        Double sec = (Datetime.now ().getTime() - pauseTimeGMT.getTime()) / 1000;
        System.debug ('sec ==> ' + sec);
        return startTimeGMT.addSeconds(Integer.valueOf (sec));
    }

    // A method that returns wrapper instance of timer controller class
    public static TimerController.TimeEntryWrapper createWrpInstance (Time_Entry__c pTimeEntry) {
        if (pTimeEntry == null) return null;
        Decimal totMins = pTimeEntry.Timer_Total_Mins__c;
        Decimal hh = Math.floor (totMins /60);
        Integer mm = Math.mod (Integer.valueOf (totMins), 60);
        Boolean isPause = pTimeEntry.Pause_Time__c == null ? false : true;
        return new TimerController.TimeEntryWrapper ( pTimeEntry,
                                            Integer.valueOf (hh) + ':' + mm + ':0',
                                            isPause);
    } // End method

    // A method to return name of the month
    public static Map<Integer, String> monthName = 
        new Map<Integer, String> {
        1 => 'Jan',
        2 => 'Feb',
        3 => 'Mar',
        4 => 'Apr',
        5 => 'May',
        6 => 'June',
        7 => 'July',
        8 => 'Aug',
        9 => 'Sept',
        10 => 'Oct',
        11 => 'Nov',
        12 => 'Dec'
    };
}