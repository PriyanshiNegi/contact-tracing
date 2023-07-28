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

}