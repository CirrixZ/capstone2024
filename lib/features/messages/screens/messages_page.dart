import 'package:capstone/features/auth/components/ban_check.dart';
import 'package:capstone/features/messages/widgets/carpool_chat_tab.dart';
import 'package:capstone/features/messages/widgets/group_chat_tab.dart';
import 'package:capstone/features/notifications/widgets/notification_badge.dart';
import 'package:flutter/material.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return BanCheck(
      child: Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: const Color(0xFF180B2D),
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          actions: <Widget>[
            NotificationIconButton(),
          ],
        ),
        body: Column(
          children: [
            // "Messages" text above the TabBar
            Center(
              child: Text(
                "Messages",
                style: TextStyle(
                  fontSize: 22, // Adjust font size
                  fontWeight: FontWeight.bold, // Makes the text bold
                  color: Colors.white, // Text color
                ),
              ),
            ),
            SizedBox(height: 10),
            TabBar(
              controller: _tabController,
              labelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              tabs: [
                Tab(text: "Group Chats"),
                Tab(text: "Carpools"),
              ],
              labelColor: Color(0xFF7000FF),
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(), // This removes the indicator line
              dividerColor: Colors.transparent, // This removes the divider
            ),

            // Tab Bar View (the content below the tabs)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  GroupChatsTab(),
                  CarpoolsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
