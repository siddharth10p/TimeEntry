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

    public static Datetime retrieveElapsedDate (Datetime pStartTime, Datetime pPauseTime) {
        if (pStartTime == null || pPauseTime == null)
            return null;
        Double sec = (Datetime.now ().getTime() - pPauseTime.getTime()) / 1000;
        pStartTime.addSeconds(Integer.valueOf (sec));
        return pStartTime;
    }

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