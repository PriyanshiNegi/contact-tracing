public class CTLocationTracingController {

    public static list<Location_Tracing__c> getVisitors(String locationId){
        return [SELECT Id, Person__c,Location__c,Visit_Date__c, Person__r.Token__c,Person__r.Health_Status__c 
                       FROM Location_Tracing__c 
                       WHERE Id =: locationId 
                       ORDER BY Visit_Date__c DESC];
    }

    public static list<Location_Tracing__c> getLocationsByPersonIds(Set<Id> personIds){
        return [SELECT Id,Name , Person__c,Location__c
                       FROM Location_Tracing__c
                       WHERE Person__c IN :personIds
                       AND Visit_Date__c = LAST_N_DAYS :10];
    }

    public static List<Location_Tracing__c> getLocationsByLocationIds(Set<Id> locationIds){
       return [SELECT Id,Name , Person__c,Location__c
                    FROM Location_Tracing__c 
                    WHERE Location__c IN : locationIds 
                    AND  Person__r.Health_Status__c = 'Green' 
                    AND Visit_Date__c = LAST_N_DAYS :10] ;
    }

    //checking if duplication locations are being added
    public static List<Location_Tracing__c> checkDuplicates(List<Location_Tracing__c> locationTraces){
        
        //store unique location ids
        Set<Id> locationIds = new Set<Id>();
        //store unique person ids
        Set<Id> personIds = new Set<Id>();

        //Getting the Location and Person Id from the list that was input
        for( Location_Tracing__c trace : locationTraces){
            locationIds.add(trace.Location__c);
            personIds.add(trace.Person__c);
        }

        //Getting the already present tracing locations and copying only the ones that are also present in the input list given to us
        List<Location_Tracing__c> existingRecords = [SELECT Id, Person__c,Location__c
                       FROM Location_Tracing__c 
                       WHERE Location__c IN : locationIds
                       AND Person__c IN : personIds];


        Map<Id, Set<Id>> mapOfExistingRecords = new Map<Id, Set<Id>>();
        
         //list of duplicate records
         List<Location_Tracing__c> duplicate = new List<Location_Tracing__c>();


         //We need Location wise unique Person since Location can be common for People
         
        //since if there are existing records that have been mapped that means there are duplicates                       
        if(existingRecords !=null && existingRecords.size()>0){
            for(Location_Tracing__c trace :existingRecords){
                //if location is not present in map then add that location to new Map and create a Set to add all Person to that Location
                if(! mapOfExistingRecords.containsKey(trace.Location__c)){
                    mapOfExistingRecords.put(trace.Location__c, new Set<Id>());
                }
                //if the location is already present in the Map then add the person from the location to Map
                mapOfExistingRecords.get(trace.Location__c).add(trace.Person__c);
            }
        }

        for( Location_Tracing__c trace : locationTraces){
            //if Map already has that Location and Person that means the List value is duplicate
            if(mapOfExistingRecords.containsKey(trace.Location__c) && mapOfExistingRecords.get(trace.Location__c).contains(trace.Person__c)){
                duplicate.add(trace);
            }
        }

        return duplicate;
    }

}


/*

---------------------ANOTHER WAY 56-63 -------------------------
String locationId = trace.Location__c;
String personId = trace.Person__c;

if(! mapOfExistingRecords.containsKey(locationId)){
    mapOfExistingRecords.put(locationId,new Set<Id>());
}
Set<Id> personIds = mapOfExistingRecords.get(locationId);
personIds.add(personId);

mapOfExistingRecords.put(locationIds,personIds);
*/