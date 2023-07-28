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


}