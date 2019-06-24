import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter Password Resolver'),
        ),
        body: MyHomePage()
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isActive = false;
  List<String> passwords;
  String input = "";

  @override
  void initState() {
    isActive = false;
    passwords = [];
    super.initState();
  }

  Future<num> _resolve(BuildContext context) async {
    setState(() {
      isActive = true;
    });

    FocusScope.of(context).requestFocus(new FocusNode());
    
    var stopWatch = Stopwatch();
    stopWatch.start();
    var variants = await compute(_getResolvedValues, input);
  
    print("Setting new results...");

    setState(() {
      isActive = false;
      passwords = variants;
    });

    stopWatch.stop();
    
    print("Elapsed time: ${stopWatch.elapsed.inMilliseconds / 1000} s");
    return stopWatch.elapsed.inMilliseconds / 1000;
  }
  
  static Future<List<String>> _getResolvedValues(String input) async {
    return await VariantsManager().resolve(input);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Expanded(
                        child: TextField(
                          onChanged: (text) {
                            setState(() {
                              input = text;
                            });
                          },
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter a search term'),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(8, 0, 8, 0),
                      child: RaisedButton(
                          onPressed: !isActive
                              ? () async {
                            var time = await _resolve(context);
                            print("Showing snackbar");
                            Scaffold.of(context).showSnackBar(SnackBar(content: Text("Time: $time s")));
                          }
                              : null,
                          child: Row(
                            children: <Widget>[
                              Text('Resolve'),
                              Container(
                                margin: EdgeInsets.fromLTRB(16, 0, 0, 0),
                                child: isActive
                                    ? SizedBox(
                                  height: 12,
                                  width: 12,
                                  child: CircularProgressIndicator(
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                                    : null,
                              )
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemBuilder: (buildContext, row) {
              final password = passwords[row];
              return Container(
                height: 50,
                padding: EdgeInsets.all(8),
                child: Text(password),
              );
            },
            itemCount: passwords.length,
          ),
        )
      ],
    );
  }
}

class VariantsManager {
  final cifers = [
    ["!", "@", "\$", "#"],
    ["(", "_", "-", ")"],
    ["a", "b", "c", "^"],
    ["d", "e", "f", "*"],
    ["g", "h", "i", "A"],
    ["j", "k", "l", "B"],
    ["m", "n", "o", "C"],
    ["p", "q", "r", "D"],
    ["s", "t", "u", "v"],
    ["w", "x", "y", "z"]
  ];

  List<List<String>> interestedList = [];

  Future<List<String>> resolve(String input) async {
    interestedList = [];
    List<List<String>> variants = await _resolveValues(input);
    
    print("Got results...");
    List<String> results = [];
    for(List<String> compute in variants) {
      for(String variant in compute) {
        results.add(variant);
      }
    }
    print("Mapped results");
    return results;
  }

  Future<List<List<String>>> _resolveValues(String input) async {
    if (input.length == 0) {
      return Future<List<List<String>>>.value([]);
    }

    for (int i = 0; i < input.length; i++) {
      var char = input[i];
      var index = int.parse(char);
      interestedList.add(cifers[index]);
    }

    if (interestedList.length == 1) {
      return Future<List<List<String>>>.value([interestedList[0]]);
    }

    print("Start computations...");
    
    var results = Future.wait([
      compute(_getVariants, VariantsCalculationObject("A", interestedList[0], 1, 0, interestedList)),
      compute(_getVariants, VariantsCalculationObject("B", interestedList[0], 1, 1, interestedList)),
      compute(_getVariants, VariantsCalculationObject("C", interestedList[0], 1, 2, interestedList)),
      compute(_getVariants, VariantsCalculationObject("D", interestedList[0], 1, 3, interestedList)),
    ]);
  
    print("Finish computations");
    
    return results;
  }

  static List<String> _getVariants(VariantsCalculationObject obj) {
    
    if (obj.nextIndex >= obj.interestedList.length) {
      return obj.symbList;
    }

    List<String> variants =
        _getVariants(VariantsCalculationObject(null, obj.interestedList[obj.nextIndex], obj.nextIndex + 1, null, obj.interestedList));

    List<String> results = [];

    if (obj.index != null) {
      for (String variant in variants) {
        results.add(obj.symbList[obj.index] + variant);
      }
    } else {
      for (String symb in obj.symbList) {
        for (String variant in variants) {
          results.add(symb + variant);
        }
      }
    }
    
    if (obj.computationId != null) {
      print("Finished computation: ${obj.computationId}");
    }
    
    return results;
  }
}

class VariantsCalculationObject {
  final String computationId;
  final List<String> symbList;
  final int nextIndex;
  final int index;
  final List<List<String>> interestedList;
  
  VariantsCalculationObject(
      this.computationId,
      this.symbList,
      this.nextIndex,
      this.index,
      this.interestedList
  );
}