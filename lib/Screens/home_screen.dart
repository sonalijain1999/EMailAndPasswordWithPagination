
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:riverpodauth/Models/api_model.dart';

import 'package:riverpodauth/Models/user_model.dart';
import 'package:http/http.dart' as http;
import 'login_screen.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //pagination login start
  int currentPage = 1;

  late int totalPages;

  List<APIData> api_data = [];

  final RefreshController refreshController =
  RefreshController(initialRefresh: true);

  Future<bool> getApiData({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage = 1;
    } else {
      if (currentPage >= totalPages) {
        refreshController.loadNoData();
        return false;
      }
    }

    final Uri uri = Uri.parse(
        "https://reqres.in/api/users?page=$currentPage");

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final result = welcomeFromJson(response.body);

      if (isRefresh) {
        api_data = result.data;
      } else {
        api_data.addAll(result.data);
      }

      currentPage++;

      totalPages = 2; // or result.totalPages;

      print(response.body);
      setState(() {});
      return true;
    } else {
      return false;
    }
  }

  //pagination login end
  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();

  @override
  void initState() {
    super.initState();
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((value) {
      this.loggedInUser = UserModel.fromMap(value.data());
      setState(() {});
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        leading: ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: Colors.white38,
              fixedSize: const Size(300, 100),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50))),
          // Within the `FirstRoute` widget
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Profile()),
            );
          },
          child: const Text("Profile",
          style: TextStyle(fontSize: 7),),
        ),
        centerTitle: true,
      ),
      body: SmartRefresher(
        controller: refreshController,
        enablePullUp: true,
        onRefresh: () async {
          final result = await getApiData(isRefresh: true);
          if (result) {
            refreshController.refreshCompleted();
          } else {
            refreshController.refreshFailed();
          }
        },
        onLoading: () async {
          final result = await getApiData();
          if (result) {
            refreshController.loadComplete();
          } else {
            refreshController.loadFailed();
          }
        },
        child: ListView.separated(
          itemBuilder: (context, index) {
            final passenger = api_data[index];

            return ListTile(
                title: Text(passenger.firstName),
                subtitle: Text(passenger.email),
                trailing: Image(image: NetworkImage(passenger.avatar))
            );
          },
          separatorBuilder: (context, index) => Divider(),
          itemCount: api_data.length,
        ),
      ),

    );
  }

  // the logout function
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()));
  }
}