({  doInit : function (component, event, helper) {
    //alert ('Hi');
        helper.updateTimer (component, event, helper);
    	helper.setProjId (component, event, helper);
    	helper.retrieveProjects (component, event, helper);
	},
	startTimer : function (component, event, helper) {
    	//helper.updateStartTime (component, event, helper);
    	helper.createTimeEntry (component);
	},
    
  	disTasks : function (component, event, helper) {
        //alert (component);
    	helper.retrieveTasks (component, event, helper);
  	},
    pauseTimer : function (component, event, helper) {
        helper.pause (component);
    },
    
    resumeTimer : function (component, event, helper) {
        helper.resume (component);
    },
    
    save : function (component, event, helper) {
    	helper.saveTime (component, event, helper);
	}
})