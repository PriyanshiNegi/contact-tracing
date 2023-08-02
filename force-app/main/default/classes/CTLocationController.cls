public class CTLocationController {

    public static List<Location__c> getRecentStatusChanges(){
         return [SELECT Id, Name, Pincode__c, Address__c, Red_Score__c, Status_Update_Date__c, Status__c FROM Location__c ORDER BY Status_Update_Date__c DESC NULLS LAST LIMIT 100];
    }

    public static List<Location__c> searchLocations(String searchTerm){
        searchTerm = searchTerm + '%';
        return [SELECT Id, Name, Pincode__c, Address__c, Red_Score__c, Status_Update_Date__c, Status__c FROM Location__c WHERE Name LIKE :searchTerm OR Pincode__c   LIKE :searchTerm OR Address__c LIKE : searchTerm  ORDER BY Status_Update_Date__c NULLS LAST LIMIT 100];
    }

    public static Location__c getLocationById(String locationId){
        List<Location__c> loc= [SELECT Id, Name, Pincode__c, Address__c, Red_Score__c, Status_Update_Date__c, Status__c FROM Location__c WHERE Id=:locationId];
        if(loc != null && loc.size()>0){
            return loc[0];
        }
        return null;
    }

    public static Map<String,Integer> getStatusCount(){

        //map to location with status
        Map<String,Integer> statusCount = new Map<String,Integer>();

        for( AggregateResult r : [SELECT Status__c, COUNT(Id) c  FROM Location__c GROUP BY Status__c] ){
            //type casting to String and Integer
            String status = String.valueOf(r.get('Status__c'));
            Integer num = Integer.valueOf(r.get('c'));
            statusCount.put(status,num);
        }

        return statusCount;

    }

    public static void updateRedScore(Set<Id> locationIds){
        //locationToUpdate
        List<Location__c> loc = new List<Location__c>();
        AggregateResult[] redPeoplePerLocation = [SELECT Location__c FROM Location_Tracing__c 
              WHERE Person__r.Health_Status__c = 'Red'
              AND Visit_Date__c = LAST_N_DAYS : 10
              AND Location__c IN : locationIds 
              GROUP BY Location__c];//since we need the number of people in red at a location

        for(AggregateResult agr : redPeoplePerLocation){
            String locationId = String.valueOf(agr.get('Location__c'));
            Integer redScore = Integer.valueOf(agr.get('total'));
            String status = getStatus(redScore);
            loc.add(new Location__c(Id=locationId,Red_Score__c=redScore,Status__c=status));
        }
        if(loc!=null && loc.size()>0){
            update loc;
        }
    }

    public static String getStatus(Integer redScore){
        if(redScore == 0){
            return 'Green';
        }
        else if(redScore <= 5){
            return 'Yellow';
        }
        else if(redScore <=10) {
            return 'Orange';
        }
        else{
            return 'Red';
        }
    }
}