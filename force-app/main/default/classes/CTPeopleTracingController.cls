public class CTPeopleTracingController {

    public static List<People_Tracing__c> getTraces (String personId){

    //Person 1 meets Person 2 OR Person 2 meets Person 1 both are the same thing thus this needs to be checked both ways
       return [SELECT Id,Contact_Date__c,Person_1__c,Person_1__r.Health_Status__c, Person_1__r.Token__c ,Person_2__c,Person_2__r.Health_Status__c , Person_2__r.Token__c
                      FROM People_Tracing__c 
                      WHERE Person_1__c=:personId 
                             OR Person_2__c =:personId 
                      ORDER BY Contact_Date__c DESC];
    }

    public static List<People_Tracing__c> checkDuplicates(List<People_Tracing__c> peopleTraces){
         
        //to store unique Person ids from input String
        Set<Id> personId = new Set<Id>();

        //the person could be present in Person1 OR Person2 so we are adding both to not miss a single person and we maintain unqiue people records 
        //as we are using set so will store only one occurance of that value
        for( People_Tracing__c trace : peopleTraces){
            personId.add(trace.Person_1__c);
            personId.add(trace.Person_2__c);
        }

        // Getting already present people both 1 and 2 and copying only the ones that are also present in the input list given to us
        // meaning creating a unique list of people from already present people list
        List<People_Tracing__c> existingRecords = [SELECT Id, Person_1__c,Person_2__c
                       FROM People_Tracing__c 
                       WHERE Person_1__c IN : personId
                       OR Person_2__c IN : personId];
         
         // id = person and Set = all the people that this person has met
         Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>();

         List<People_Tracing__c> duplicate = new List<People_Tracing__c>();

        //checking if existing records comeup to be empty         
        if(existingRecords !=null && existingRecords.size()>0){
            for(People_Tracing__c trace :existingRecords){
                //if person 1 is not present add it
                if(! mapOfExistingRecords.containsKey(trace.Person_1__c)){
                    mapOfExistingRecords.put(trace.Person_1__c, new Set<Id>());
                }
                //if the person 1 is already present in the Map then add other person as person 2
                mapOfExistingRecords.get(trace.Person_1__c).add(trace.Person_2__c);

                //we need the same for Person2 as well (as 1 meets 2 or 2 meets 1 same thing we need unique)
                if(! mapOfExistingRecords.containsKey(trace.Person_2__c)){
                    mapOfExistingRecords.put(trace.Person_2__c, new Set<Id>());
                }
                mapOfExistingRecords.get(trace.Person_2__c).add(trace.Person_1__c);
            }
        }

        for( People_Tracing__c trace : peopleTraces){
            //if Map already has Person 1 and Person 2 that means the List value is duplicate OR if 
            if(mapOfExistingRecords.containsKey(trace.Person_1__c) && mapOfExistingRecords.get(trace.Person_1__c).contains(trace.Person_2__c) ||
            //Map already has Person 2 and Person 1 that means the List value is duplicate
               mapOfExistingRecords.containsKey(trace.Person_2__c) && mapOfExistingRecords.get(trace.Person_2__c).contains(trace.Person_1__c) ){
                duplicate.add(trace);
            }
        }

        return duplicate;
    }

}