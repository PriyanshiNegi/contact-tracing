public class CTPersonController {

    //create an encrypted Token from Phone Number
    public static String getToken(String mobileNo){
        
        //first converting String to Blob to be passed into the Crypto class method
        Blob value = Blob.valueOf(mobileNo);
        
        //MD5 is the name of the algorithm being used , here the value being returned is a Blob and we need a String
		Blob hash = Crypto.generateDigest('MD5', value);
        
        //has converted to String and then returned
        // return hash.toString(); could also be used but there is an issue with encoding of a Blob
        //ERROR : error blob is not a valid utf-8 string thus we return encoded String

        return EncodingUtil.base64Encode(hash);
    }

    //getting people whose healths have recently changed and sorting so that the recently changes ones come up first
    public static List<Person__c> getRecentHealthChanges(){
       List<Person__c> per =[SELECT Id, Name, Health_Status__c, Mobile__c,Status_Update_Date__c,Token__c  FROM Person__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
       return per;
    }

    //searchTerm% so that we can match all the names starting with this searchTerm
    public static List<Person__c> searchPeople(String searchTerm){

        //we can also use binding variable instea of 'searchTerm%' by appending % after it like 
        // searchTerm = searchTerm +'%';
        //Name LIKE : searchTerm
        List<Person__c> per =[SELECT Id, Name, Health_Status__c, Mobile__c,Status_Update_Date__c,Token__c  FROM Person__c WHERE Name LIKE 'searchTerm%' OR Mobile__c LIKE 'searchTerm%' OR Token__c LIKE 'searchTerm%' ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
        return per;
    }

    //finding that one person with ID
    public static Person__c getPersonById(String personId){

        //List is being used to avoid running into exception since sometimes the ID may not be found then it will throw error if we just take Person__c;
        List<Person__c> per =[SELECT Id, Name, Health_Status__c, Mobile__c,Status_Update_Date__c,Token__c   FROM Person__c WHERE Id =: personId];

        //in order to make sure we only retrun one person
        if(per != null && per.size()>0){
            return per[0];
        }
        return null;
    }

    public static Map<String,Integer> getHealthStatusCount(){

        //map to count people with each status
        Map<String,Integer> healthCount = new Map<String,Integer>();

        //query Person and count number of people in each health status
        AggregateResult[] result = [SELECT Health_Status__c, COUNT(Id) c  FROM Person__c GROUP BY Health_Status__c]; //can be stored like this or directly in the for loop

        //putting values in the Map
        for( AggregateResult r : result ){
            //type casting to String and Integer
            String health = String.valueOf(r.get('Health_Status__c'));
            Integer num = Integer.valueOf(r.get('c'));
            healthCount.put(health,num);
        }

        return healthCount;

    }

    //getting cohabitants
    public static Set<Id> getCohabitants(Set<Id> personIds){
       List<String> healthStatuses = new List<String>{'Green','Yellow'};
       List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c 
                                                    WHERE (Person_1__c IN : personIds OR Person_2__c IN : personIds) 
                                                    AND Contact_Type__c='Cohabitant'
                                                    AND (Person_1__r.Health_Status__c IN : healthStatuses OR Person_2__r.Health_Status__c IN : healthStatuses)];
    //It can so happen that we get Person 1 back for example : 
    // *Shaddy --> Priyanshi
    // Priyanshi ---> Shailja
    // Shailja ---> *Shaddy so we should be able to identify the unique ones which we can do by finding the difference between input set of PersonIds and peopleTraces
    //because the common one has been already checked refer the example above
        Set<Id> cohabitants = new  Set<Id>();
        for(People_Tracing__c pt : peopleTraces){
            if(! personIds.contains(pt.Person_1__c)){
                cohabitants.add(Person_1__c.Id);
            }
            if(! personIds.contains(pt.Person_2__c)){
                cohabitants.add(Person_2__c.Id);
            }
        }
        return cohabitants;
    }

    //getting neighbours
    public static Set<Id> getNeighbours(Set<Id> personIds){
        //we need to mark all neighbours yellow, except red/orange/yellow i.e if they are green mark yellow
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c 
                                                     WHERE (Person_1__c IN : personIds OR Person_2__c IN : personIds) 
                                                     AND Contact_Type__c='Neighbour'
                                                     AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')];
         Set<Id> neighbours = new  Set<Id>();
         for(People_Tracing__c pt : peopleTraces){
             if(! personIds.contains(pt.Person_1__c)){
                neighbours.add(Person_1__c.Id);
             }
             if(! personIds.contains(pt.Person_2__c)){
                neighbours.add(Person_2__c.Id);
             }
         }
         return neighbours;
    }

      //getting primaryContacts
      // *Shaddy --> Priyanshi
      // Priyanshi ---> Shailja
      // Shailja ---> *Shaddy here Priyanshi is Primary contact for Shaddy whereas Shailja is Secondary
    public static Set<Id> getPrimaryContact(Set<Id> personIds){
       List<String> healthStatuses = new List<String>{'Green','Yellow'};
       List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c 
                                                     WHERE (Person_1__c IN : personIds OR Person_2__c IN : personIds) 
                                                     AND Contact_Type__c='Other'
                                                     AND Contact_Date__c = LAST_N_DAYS : 10
                                                     AND (Person_1__r.Health_Status__c IN : healthStatuses OR Person_2__r.Health_Status__c IN : healthStatuses)];
         Set<Id> primaryContacts = new  Set<Id>();
         for(People_Tracing__c pt : peopleTraces){
             if(! personIds.contains(pt.Person_1__c)){
                primaryContacts.add(Person_1__c.Id);
             }
             if(! personIds.contains(pt.Person_2__c)){
                primaryContacts.add(Person_2__c.Id);
             }
         }
         return primaryContacts;
    }

    //getting secondaryContacts we can directly pass the primaryContact IDs and get secondaryContactIds by the same way
    public static Set<Id> getsecondaryContacts(Set<Id> primaryContactIds){
        //we need to pass the Id for the Primary Contact in order to get to Secondary Contact
        List<People_Tracing__c> peopleTraces = [SELECT Id, Person_1__c, Person_2__c FROM People_Tracing__c 
                                                     WHERE (Person_1__c IN : primaryContactIds or Person_2__c IN : primaryContactIds) 
                                                     AND Contact_Type__c ='Other'
                                                     AND Contact_Date__c = LAST_N_DAYS :10
                                                     AND (Person_1__r.Health_Status__c = 'Green' OR Person_2__r.Health_Status__c = 'Green')];
         Set<Id> secondaryContacts = new  Set<Id>();
         for(People_Tracing__c pt : peopleTraces){
             if(! primaryContactIds.contains(pt.Person_1__c)){
                secondaryContacts.add(Person_1__c.Id);
             }
             if(! primaryContactIds.contains(pt.Person_2__c)){
                secondaryContacts.add(Person_2__c.Id);
             }
         }
         return secondaryContacts;
     }
}