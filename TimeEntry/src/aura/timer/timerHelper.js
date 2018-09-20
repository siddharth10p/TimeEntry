({
	start : function (h, m, s, cmp) {
       // cmp.set ("v.showTimer", true);
        var tVal = setInterval(function () {
        	if (s == 59) {
            	if (m == 59) {
                	h = h + 1;
               		m = 0;
            } else {
                m = m + 1;
            }
            s = -1; 
        	}
        	s = s + 1;
        	cmp.set ("v.timeVal", h + ":"+ m + ":" + s);
            }, 1000);
        cmp.set ("v.intervalId", tVal);
    },
    
    setProjId : function (cmp, evnt, helper) {
        var objId = cmp.get ("v.recordId");
		if (objId) cmp.find("p_opt").set("v.value", objId);
        this.fetchTaskId (cmp); // Setting the default task
        this.retrieveTasks (cmp, evnt, helper); // fetching the tasks
    },

    fetchTaskId : function (cmp) {
        var action = cmp.get ("c.fetchTaskId");
        action.setParams ({
            pProjectId : cmp.get ("v.recordId")
        });
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
                
            } else if (state === 'SUCCESS') {
                var taskId = response.getReturnValue();
                cmp.find("t_opt").set("v.value", taskId);
            } 
        });
        $A.enqueueAction(action);
    },

    retrieveTasks : function (cmp, evnt, helper) {
        var projSel = cmp.find("p_opt").get("v.value");
     	//cmp.set ("v.projId", projSel);
        var action = cmp.get ("c.fetchTasks");
        action.setParams ({
            pProjectId : projSel
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                var tasks = response.getReturnValue ();
                cmp.set ("v.tasks", tasks);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
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
    },
 
    createTimeEntry : function (cmp) {
        var pTimeVal = cmp.get ("v.timeValBk");
        if (pTimeVal) {
        	var timeArry = pTimeVal.split (':');
        	if (timeArry.length == 3) { // A timer is already running
            	alert ("Click on Resume instead of Start!");
            	return null;
        	}
        }
        var proId = cmp.find("p_opt").get("v.value");
        var taskId = cmp.find("t_opt").get("v.value");
        if (taskId && proId) {
            var action = cmp.get ("c.createTimeEntry");
            action.setParams ({
                pProjId : proId,
                pTaskId : taskId
            });
            action.setCallback (this, function (response) {
                var state = response.getState ();
                if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                     errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                
                } else if (state === 'SUCCESS') {
                    var timeID = response.getReturnValue();
                    if (timeID)
                        cmp.set ("v.timeEntryId", timeID);
                } 
            });
            $A.enqueueAction(action);
       		this.start (0, 0, 0, cmp); // kick off the timer
        } else
            alert ('Kindly select a valid project and task');
    },
    
    updateTimer : function (cmp, evnt, helper) {
        var action = cmp.get ("c.getTotalMins");
        action.setParams ({
            pProjId : cmp.get ("v.recordId")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
            else if (state === 'SUCCESS') {
                cmp.set ("v.wrpValue", response.getReturnValue ());
                cmp.set ("v.timeEntryId",  cmp.get ("v.wrpValue[timeEntryId]"));
                var proId = cmp.get ("v.wrpValue[projId]");
                if (proId) cmp.find("p_opt").set("v.value", proId);
                var taskId = cmp.get ("v.wrpValue[taskId]");
                if (taskId) cmp.find("t_opt").set("v.value", taskId);
                var time = cmp.get ("v.wrpValue[currTime]");
                if (time) {
                    var formatTime = time.replace(/, /g, ":");
                    var addSecond = formatTime.concat(":0");
                	cmp.set ("v.timeValBk", addSecond);
                    var pause = cmp.get ("v.wrpValue[isPause]");
                    this.blinkTimeVal (pause, addSecond, cmp);
                } else {
                    cmp.set ("v.timeVal", "");   
                	cmp.set ("v.timeValBk", "v.timeVal"); // Setting the same value for backend attribute
                }
            }
        });
        $A.enqueueAction(action);
    },
    
    blinkTimeVal : function (pause, ptimeVal, cmp) {
        cmp.set ("v.timeValBk", ptimeVal);
        if (pause) {
            var timeVal;
            var tVal = setInterval(function () {
                timeVal = (timeVal== " " ? ptimeVal : " ");
                cmp.set ("v.timeVal", timeVal);
            }, 1000);
            cmp.set ("v.intervalId", tVal);
            
        } else {
            var timeArry = ptimeVal.split (':');
            var hh = parseInt (timeArry[0]);
            var mm = parseInt (timeArry[1]);
            var ss = parseInt (timeArry[2]);
            this.start (hh, mm, ss, cmp);
        }
    },

    saveTime : function (cmp, evnt, helper) {
        var action = cmp.get ("c.updateTime");
        action.setParams ({
            pRecId : cmp.get ("v.timeEntryId"),
            pTime : this.formatTime (cmp.get ("v.timeValBk")),
            pNote : cmp.get ("v.note")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                 errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            
            } else if (state === 'SUCCESS'){
				alert ('Time logged!');
            } else {
				// do nothing
			}
        });
        $A.enqueueAction(action);
    },
    
	fetchTask : function (cmp) {
		var action = cmp.get ("c.fetchTask");
        action.setParams ({
            pTaskId : cmp.get ("v.recordId")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                var task = response.getReturnValue ();
                cmp.set ("v.taskObj", task);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
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
	},
	
    retrieveProjects : function (cmp, evnt, helper) {
        var action = cmp.get ("c.fetchAllProjects");
        action.setParams ({
            pProjId : cmp.get ("v.recordId")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                var projects = response.getReturnValue ();
                cmp.set ("v.projects", projects);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
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
    },
    
    formatTime : function (pTime) {
    	var time = pTime.split(":");
        if (time[2].lenght == 2)
        	return pTime.slice(0, -3);
       	else
            return pTime.slice(0, -2);
    },
    
    pause :  function (cmp) {
        var temp = cmp.get ("v.intervalId");
        clearInterval (temp);
        var action = cmp.get ("c.updatePauseTime");
        action.setParams ({
            pTimeEntryId : cmp.get ("v.timeEntryId")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                console.log ("Pause time updated successfully!");
        		this.blinkTimeVal (true, cmp.get ("v.timeVal"), cmp);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
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
    },
    
    resume : function (cmp) {
        var value = cmp.get ("v.timeValBk");
        var time = value.split(":");
        var action = cmp.get ("c.updateElapsedTime");
        action.setParams ({
            pTimeEntryId : cmp.get ("v.timeEntryId")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                console.log ("Pause time updated successfully!");
                var temp = cmp.get ("v.intervalId");
                clearInterval (temp);
                this.start (parseInt(time[0], 10), parseInt(time[1], 10),
                            parseInt(time[2], 10), cmp);
            } else if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
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