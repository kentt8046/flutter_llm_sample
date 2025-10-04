import 'package:flutter/cupertino.dart';
import 'package:flutter_apple_llm/flutter_apple_llm.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final textEditingController = TextEditingController();

  AppleLanguageModelSession? session;
  final messages = <ChatMessage>[];
  var initialized = false;
  var isAvailable = false;

  @override
  void initState() {
    super.initState();

    Future(() async {
      isAvailable = await AppleLanguageModelSession.isAvailable();

      if (isAvailable) await newSession();

      setState(() {
        initialized = true;
      });
    });
  }

  Future<void> newSession() async {
    await session?.dispose();
    messages.clear();
    session = await AppleLanguageModelSession.start();
  }

  Future<void> respond(String content) async {
    final stream = session!.respond(content);
    setState(() {
      messages
        ..add(ChatMessage(content: content, isUser: true))
        ..add(ChatMessage(content: "", isUser: false));
    });

    await for (final chunk in stream) {
      setState(() {
        messages[messages.length - 1] = ChatMessage(
          content: chunk,
          isUser: false,
        );
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (initialized && isAvailable)
              Row(
                children: [
                  Spacer(),
                  CupertinoButton(
                    onPressed: () async {
                      await newSession();
                      setState(() {});
                    },
                    child: Icon(CupertinoIcons.refresh),
                  ),
                ],
              ),
            Expanded(
              child: SingleChildScrollView(
                child: switch ((initialized, isAvailable)) {
                  (false, _) => Center(child: CupertinoActivityIndicator()),
                  (true, false) => Center(
                    child: Text("Apple LLM is not available."),
                  ),
                  (true, true) => Column(
                    spacing: 8,
                    children: [
                      for (final (i, message) in messages.indexed)
                        Container(
                          alignment: message.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          padding: EdgeInsets.all(8),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: message.isUser
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.systemGrey4,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GptMarkdown(
                              "${message.content}${session?.isResponding == true && i == messages.length - 1 ? "..." : ""}",
                              style: TextStyle(
                                color: message.isUser
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                },
              ),
            ),
            if (initialized && isAvailable)
              Container(
                padding: EdgeInsets.all(8).copyWith(bottom: 8 + bottomPadding),
                decoration: BoxDecoration(color: CupertinoColors.systemGrey6),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: textEditingController,
                        readOnly: session?.isResponding == true,
                        maxLines: 5,
                        minLines: 1,
                      ),
                    ),
                    CupertinoButton(
                      onPressed: session?.isResponding == true
                          ? null
                          : () {
                              final content = textEditingController.text;
                              textEditingController.value = TextEditingValue();
                              respond(content);
                            },
                      child: Text('Send'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  ChatMessage({required this.content, required this.isUser});

  final String content;
  final bool isUser;
}
