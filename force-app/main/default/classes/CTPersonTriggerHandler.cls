public with sharing class CTPersonTriggerHandler {
    
    public static void beforeInsert(List<Person__c> newPerson){
        //looping over the list of new Person records
        for(Person__c per : newPerson){
            //setting health status to green
            per.Health_Status__c = 'Green';
            //generating Token for Person
            per.Token__c = CTPersonController.getToken(per.Mobile__c);
        }
    }

    public static void beforeUpdate(List<Person__c> newPerson, Map<Id,Person__c> oldPerson){
         //when health status updates then update the Status_Update_Date__c field
         for(Person__c per : newPerson){
            //if the new health status is not equal to old status
            if(per.Health_Status__c != oldPerson.get(per.Id).Health_Status__c){
                per.Status_Update_Date__c = Date.today();
            }
         }
    }
}