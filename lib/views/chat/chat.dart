import 'dart:async';
import 'package:chat/core/base_state.dart';
import 'package:chat/helper/socket_helper.dart';
import 'package:chat/helper/stream_controller_helper.dart';
import 'package:chat/main.dart';
import 'package:chat/viewmodel/chat/chat_view_model_list.dart';
import 'package:chat/views/chat/message_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ChatView extends StatefulWidget {
  final String receiverID;
  final String clientName;

  ChatView({this.receiverID, this.clientName});

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends BaseState<ChatView> {
  TextEditingController _messageController = TextEditingController();
  ScrollController _controller = ScrollController();
  StreamSubscription<int> subscription;
  final FocusNode focusNode = FocusNode();

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  var vm = getIt<ChatListState>();

  @override
  void initState() {
    super.initState();
    getMessages();
  }

  @override
  void dispose() async {
    subscription.cancel();
    _controller.dispose();
    _messageController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  getMessages() async {
    subscription = StreamControllerHelper.shared.stream.listen((index) {
      if (index > 1) {
        itemScrollController.scrollTo(
            index: index - 1, duration: Duration(milliseconds: 500));
      }
    });
    await vm.fetchMessage(widget.receiverID);
    if(vm.messageStatus != MessageStatus.empty)
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      itemScrollController.jumpTo(index: vm.messageList.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    if(vm.messageStatus != MessageStatus.empty)
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      itemScrollController.scrollTo(
          index: vm.messageList.length - 1,
          duration: Duration(milliseconds: 200));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientName),
      ),
      body: Column(
        children: [
          Flexible(child: buildChatScreen()),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 4,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    child: TextField(
                        maxLines: null,
                        style: TextStyle(fontSize: 16.0),
                        controller: _messageController,
                        decoration: InputDecoration.collapsed(
                          border: UnderlineInputBorder(),
                          hintText: 'Mesajınız',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        focusNode: focusNode),
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: FlatButton(
                      onPressed: () {
                        if (_messageController.text.trim().isNotEmpty) {
                          SocketHelper.shared.sendMessage(
                              receiver: widget.receiverID,
                              message: _messageController.text);
                          _messageController.clear();
                        }
                      },
                      child: Text("Gönder")),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildChatScreen() {
    return Observer(builder: (_) {
      if (vm.messageStatus == MessageStatus.empty) // EMPTY
        return Stack(
          children: [
            Center(child: Text('Sohbet boş duruyor. Adım atmak ister misin :)'),)
          ],
        );
      else if (vm.messageStatus == MessageStatus.loading) // LOADING
        return Center(child: CircularProgressIndicator());
      else
        return MessageListView(  // LOADED WİTH DATA
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener);
    });
  }
}