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

    public static void afterUpdate(List<Person__c> newPerson, Map<Id,Person__c> oldPerson){

        //to store change in status
        Set<Id> statusChange = new Set<Id>();
        //to store if red status
        Set<Id> redStatus = new Set<Id>();
    
        for(Person__c per : newPerson){
            //checking if the status changed
            if(per.Health_Status__c != oldPerson.get(per.Id).Health_Status__c){
                statusChange.add(per.Id);
            }
            //checking if the status changed to Red
           // if(per.Health_Status__c != oldPerson.get(per.Id).Health_Status__c && per.Health_Status__c = 'Red'){
            if(per.Health_Status__c == 'Red' && oldPerson.get(per.Id).Health_Status__c ! = 'Red'){
                redStatus.add(per.Id);
            }
        }

        //Cohabitants and Primary Contacts
        Set<Id> orangeStatus = new Set<Id>();
        //Neighbours and Secondary Contacts
        Set<Id> yellowStatus = new Set<Id>();

        //passing redStatus since we need to update only when the status for the Person changes to Red
// ------------------WE ALSO NEED TO STOP PROCESSING A RECORD WHICH HAS ALREADY BEEN PROCESSED----------------------
        //adding all cohabitants we get to the orangeStatus set
        orangeStatus.addAll(CTPersonController.getCohabitants(redStatus));
         //adding all neighbouts we get to the yellowStatus set
        yellowStatus.addAll(CTPersonController.getNeighbours(redStatus));
         //adding all primaryContacts we get to the orangeStatus set
        Set<Id> primaryContacts = CTPersonController.getPrimaryContact(redStatus);
        orangeStatus.addAll(primaryContacts);
         //adding all secondaryContact we get to the yellowStatus set , we need primaryContacts for secondryContacts 
        yellowStatus.addAll(CTPersonController.getsecondaryContacts(primaryContacts));
    }
}