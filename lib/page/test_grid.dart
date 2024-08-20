import 'package:flutter/material.dart';

/// test grid view stateful rebuild performance
///
/// seem 9 * 9 grid state change will jetlag
///
/// @TODO this file just for test will delete in the near future , do not write logic code here
class TestGridPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TestGridPageState();
}

class _TestGridPageState extends State<TestGridPage> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final axis = 9;

    final _bodyWidget = GridView.builder(
      itemCount: axis * axis,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: axis,
      ),
      itemBuilder: (context, index) {
        return GestureDetector(
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: _selected != null && _selected == index
                    ? Colors.red
                    : Colors.blue),
            child: Text(
              "$index",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          onTap: () {
            setState(() {
              if (_selected != index) {
                _selected = index;
              } else {
                _selected = null;
              }
            });
          },
        );
      },
    );
    return Scaffold(
      appBar: AppBar(title: Text("Test GridView")),
      body: _bodyWidget,
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
