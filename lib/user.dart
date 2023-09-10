class User {
  String name;
  String salary;

  User({required this.name, required this.salary});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      salary: json['salary'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'salary': salary,
      };
}
