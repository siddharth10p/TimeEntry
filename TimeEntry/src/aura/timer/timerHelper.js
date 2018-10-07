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
            cmp.set ("v.timeValBk", "v.timeVal"); // set the same time in hidden attribute
            }, 1000);
        cmp.set ("v.intervalId", tVal);
    },
    
    setProjId : function (cmp, evnt, helper) {
        var objId = cmp.get ("v.recordId");
		if (objId) cmp.find("p_opt").set("v.value", objId);
		this.updateTimer (cmp, evnt, helper); // pulling existing time entries
        //this.fetchTaskId (cmp); // Setting the default task
        //this.retrieveTasks (cmp, evnt, helper); // fetching the tasks
    },

    retrieveTasks : function (cmp, evnt, helper) {
        var projSel = cmp.get ("v.projId");//cmp.find("p_opt").get("v.value");
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
					//this.setValues (cmp, evnt, helper); // set values for timer
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
				this.updateTimer (cmp, evnt, helper); // pulling existing time entries
				//this.setProjId (cmp, evnt, helper); // Setting default values 
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
        if (cmp.get ("v.taskId") === cmp.get ("v.taskId_bk") &&
			cmp.get ("v.projId") === cmp.get ("v.projId_bk") && 
			cmp.get ("v.timeEntryId")) {
            alert ("Click on Resume instead of Start!");
            return; // skip further code execution
        }
        var proId = cmp.find("prj_opt").get("v.value");
        var taskId = cmp.find("tsk_opt").get("v.value");
        if (taskId && proId) {
            var action = cmp.get ("c.createTimeEntry");
            action.setParams ({
                pProjId : proId,
                pTaskId : taskId,
				pNotes : cmp.get ("v.note")
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
					cmp.set ("v.wrpObj", response.getReturnValue());
					cmp.set ("v.timeEntryId", cmp.get ("v.wrpObj.timeEntry.Id"));
					if (cmp.get ("v.startTimer")) {
						var temp = cmp.get ("v.intervalId");
						clearInterval (temp);
						this.start (0, 0, 0, cmp); // kick off the timer
					} else { // time logged manually without using timer
                		this.saveTime (cmp);
                    }
                } 
            });
            $A.enqueueAction(action);
        } else
            alert ('Kindly select a valid project and task');
    },
    
    updateTimer : function (cmp, evnt, helper) {
        var action = cmp.get ("c.retrieveTimeObj");
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
				cmp.set ("v.timeDataWpr", response.getReturnValue ());
                cmp.set ("v.projects", cmp.get ("v.timeDataWpr.projList"));
                cmp.set ("v.tasks", cmp.get ("v.timeDataWpr.taskList"));
                cmp.set ("v.wrpList", cmp.get ("v.timeDataWpr.timeValList"));
                cmp.set ("v.wrpObj", cmp.get ("v.wrpList[0]"));
			/*	var proId = cmp.get ("v.wrpObj.timeEntry.tesp__Project__c");
				if (!proId)
					proId = cmp.get ("v.recordId");
					cmp.set ("v.projId", proId);
					cmp.set ("v.projId_bk", proId); // backend value used in validation
				var taskId = cmp.get ("v.wrpObj.timeEntry.tesp__Task__c");
				if (taskId) {
					cmp.set ("v.taskId", taskId);
					cmp.set ("v.taskId_bk", taskId); // backend value used in validation
				} */
                this.setValues (cmp, evnt, helper); // set values for timer
            }
        });
        $A.enqueueAction(action);
    },
    
    setValues : function (cmp, evnt, helper) {
		var proId = cmp.get ("v.wrpObj.timeEntry.tesp__Project__c");
		if (!proId)
			proId = cmp.get ("v.recordId");
			cmp.set ("v.projId", proId);
			cmp.set ("v.projId_bk", proId); // backend value used in validation
		var taskId = cmp.get ("v.wrpObj.timeEntry.tesp__Task__c");
		if (taskId) {
			cmp.set ("v.taskId", taskId);
			cmp.set ("v.taskId_bk", taskId); // backend value used in validation
		}
        cmp.set ("v.timeEntryId",  cmp.get ("v.wrpObj[timeEntry.Id]"));
		cmp.set ("v.note", cmp.get ("v.wrpObj.timeEntry.tesp__Notes__c"));
        var time = cmp.get ("v.wrpObj.currTime");
        if (this.formatTime (time) === this.formatTime (cmp.get ("v.timeValBk")))
            time = cmp.get ("v.timeValBk"); // assign timer time
        if (time) {
            //cmp.set ("v.timeVal", time);
            var pause = cmp.get ("v.wrpObj.isPause");
            cmp.set ("v.pause", pause);
            this.blinkTimeVal (pause, time, cmp);
        } else {
            cmp.set ("v.timeVal", "");   
            cmp.set ("v.timeValBk", cmp.get ("v.timeVal")); // Setting the same value for backend attribute
        }
    },

    validatePause : function (cmp, evnt, helper) {
		var timerVal = cmp.get ("v.timeVal");
        if (timerVal) {
            var pause = cmp.get ("v.pause");
            if (!pause) {
                alert ("Kindly pause the timer for the current task!");
				var proId = cmp.get ("v.projId_bk");
				var taskId = cmp.get ("v.taskId_bk");
				cmp.find("prj_opt").set("v.value", proId);
				cmp.find("tsk_opt").set("v.value", taskId);
            } else {
				cmp.set ("v.note", "");
				this.retrieveTasks (cmp, evnt, helper);
				this.blinkTimeVal (true, "0:0:0", cmp);
			}
        }
       // this.retrieveTasks (cmp, evnt, helper);
    },
	
    blinkTimeVal : function (pause, ptimeVal, cmp) {
        cmp.set ("v.timeValBk", ptimeVal); // Setting the time value in backend variable
        var temp = cmp.get ("v.intervalId");
        clearInterval (temp);
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
    
    validateData : function (cmp) {
        var taskId = cmp.find("tsk_opt").get ("v.value");
        var proId = cmp.find("prj_opt").get ("v.value");
        var notes = cmp.get ("v.note");
        if (!taskId || !proId || !notes) {
            alert ("Kindly select a valid project, task and description while loggin in time!");
            return false;
        } else 
            return true;
    },
    
    saveTime : function (cmp) {
        var isValidData = this.validateData (cmp); // Validate data is set correctly
        if (!isValidData) return;
        var saveConfirm = cmp.get ("v.confirmSave");
        if (!saveConfirm) {
        	var sure = confirm ("Are you sure?");
        	if (!sure) {
            	return;
        	}
            cmp.set ("v.confirmSave", true); // confirm is true to hide the confirm dialogue if the method is called again 
        }
        if (!cmp.get ("v.timeEntryId")) {
            cmp.set ("v.startTimer", false); // Stop kicking off the timer as time is manually logged
            this.createTimeEntry (cmp);
            return; // skipping the logic as the same function is called asynchrounsly from createTimeEntry ()
        }
        //cmp.set ("v.startTimer", true);
        var timeId = cmp.get ("v.timeEntryId");
        var action = cmp.get ("c.updateTime");
        var timeVal = !cmp.get ("v.timeVal")? cmp.get ("v.timeValBk") : cmp.get ("v.timeVal");
		action.setParams ({
            pRecId : cmp.get ("v.timeEntryId"),
            pTime : this.formatTime (timeVal),
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
                cmp.set ("v.confirmSave", false);
                cmp.set ("v.timeVal", "");
                cmp.set ("v.timeValBk", "");
                cmp.set ("v.note", "");
                cmp.set ("v.taskId", "");
                cmp.set ("v.projId", cmp.get ("v.recordId"));
                var temp = cmp.get ("v.intervalId");
        		clearInterval (temp);
				alert ('Time logged!');
            } else {
				// do nothing
			}
        });
        $A.enqueueAction(action);
    },
    
    formatTime : function (pTime) {
        if (pTime) {
            var time = pTime.split(":");
            if (time.length > 2) {
                if (time[2].length == 2)
                    return pTime.slice(0, pTime.length- 3);
                else
                    return pTime.slice(0, pTime.length- 2);
            }
        }
        return pTime;
    },
    
    pause :  function (cmp) {
        if (cmp.get ("v.pause")) {
            alert ("The timer is already pause, click on Resume to continue!");
            return;
        }
		var timerVal = cmp.get ("v.timeVal");
		if (!timerVal) {
			alert ("There is no active timer to pause!");
			return;
		}
        var action = cmp.get ("c.updatePauseTime");
        action.setParams ({
            pTimeEntryId : cmp.get ("v.timeEntryId"),
            pNotes : cmp.get ("v.note")
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                console.log ("Pause time updated successfully!");
                cmp.set ("v.pause", true);
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
        var timeEntryId = cmp.find("tsk_projId").get("v.value");
        var action = cmp.get ("c.updateElapsedTime");
        action.setParams ({
            pTimeEntryId : timeEntryId
        });
        
        action.setCallback (this, function (response) {
            var state = response.getState ();
            if (state === 'SUCCESS') {
                console.log ("Elapsed time updated successfully!");
               // cmp.set ("v.pause", false);
                cmp.set ("v.wrpObj", response.getReturnValue ());
                cmp.set("v.isOpen", false);
			/*	var proId = cmp.get ("v.wrpObj.timeEntry.tesp__Project__c");
				if (!proId)
					proId = cmp.get ("v.recordId");
					cmp.set ("v.projId", proId);
					cmp.set ("v.projId_bk", proId); // backend value used in validation
				var taskId = cmp.get ("v.wrpObj.timeEntry.tesp__Task__c");
				if (taskId) {
					cmp.set ("v.taskId", taskId);
					cmp.set ("v.taskId_bk", taskId); // backend value used in validation
				} */
                this.setValues (cmp); // set values for timer
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
    
	openModel: function(cmp, event, helper) {
        if (!cmp.get ("v.pause")) {
            alert ("Kindly pause timer for existing task!");
            return;
        }
        var action = cmp.get ("c.retrieveTimeObj");
        action.setParams ({
            pProjId : null
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
				cmp.set ("v.timeDataWpr", response.getReturnValue ());
                cmp.set ("v.wrpList", cmp.get ("v.timeDataWpr.timeValList"));
      			// for Display Model,set the "isOpen" attribute to "true"
    			cmp.set("v.isOpen", true);
            }
        });
        $A.enqueueAction(action);
   	}
})