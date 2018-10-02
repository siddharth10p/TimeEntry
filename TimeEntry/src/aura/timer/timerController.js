({  doInit : function (component, event, helper) {
    //alert ('Hi');
    	//helper.retrieveProjects (component, event, helper);
		helper.updateTimer (component, event, helper);
    	//helper.setProjId (component, event, helper);
	},
	startTimer : function (component, event, helper) {
    	//helper.updateStartTime (component, event, helper);
    	helper.createTimeEntry (component);
	},
    
  	disTasks : function (component, event, helper) {
        //alert (component);
    	helper.validatePause (component, event, helper);
  	},
    pauseTimer : function (component, event, helper) {
        helper.pause (component);
    },
    
  	validate : function (component, event, helper) {
    	helper.validatePause (component, event, helper);
  	},
    resumeTimer : function (component, event, helper) {
        helper.openModel (component, event, helper);
        //helper.resume (component);
    },
    
  	continueTime : function (component, event, helper) {
  		helper.resume (component);
 	},
  
    save : function (component, event, helper) {
    	helper.saveTime (component);
	},
 
   closeModel: function(component, event, helper) {
      // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
      component.set("v.isOpen", false);
   }
})