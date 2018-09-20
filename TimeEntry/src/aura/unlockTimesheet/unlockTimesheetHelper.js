({
	unlockTimesheet : function (component) {
        var action = component.get ("c.unlockTimeEntries");
        action.setParams ({
            pTimesheetId : component.get ("v.recordId")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                component.set ("v.msg", "Timesheet unlocked successfully!");
                var dismissActionPanel = $A.get("e.force:closeQuickAction");
        		dismissActionPanel.fire();
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                        alert ("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            
            } else {
                // do nothing
            }
        });
        $A.enqueueAction(action);
	}
})