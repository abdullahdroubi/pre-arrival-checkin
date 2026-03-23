class UserModel
{
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
//constructor
  UserModel(
  {
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber
});
  //method that convert the data from json to obj
  factory UserModel.fromJson(Map<String , dynamic> json)
  {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ,
      lastName: json['last_name'] ,
      phoneNumber: json['phone_number'],
    );
  }
  //method that convert the data form obj to json
  Map<String , dynamic> toJson(){
    return{
      'id' : id,
      'email' : email,
      'first_name' : firstName,
      'last_name' : lastName ,
      'phone_number' : phoneNumber,
    };
  }
}