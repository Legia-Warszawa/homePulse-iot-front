import 'package:flutter/material.dart';
import 'package:homepulse/screns/furnance.dart';
import 'package:homepulse/screns/outside.dart';
import 'package:homepulse/screns/room.dart';
class TabsScreen  extends StatefulWidget{
  final int selectedPageIndex;
  const  TabsScreen({
    super.key,
    this.selectedPageIndex = 0
  });

  @override
  State<StatefulWidget> createState() {
    return _TabsScreenState();
  }

}
class _TabsScreenState extends State<TabsScreen>{
  int _selectedPageIndex = 0;

  final List<Widget> _pages = [
    RoomChartScreen(),      
    OutsideChartScreen(),   
    FurnaceChartScreen(),  
  ];
   @override
    void initState(){
      super.initState();
      _selectedPageIndex = widget.selectedPageIndex;
    }
    void _selectPage(int indexPage){
      setState(() {
  _selectedPageIndex = indexPage;
});
    }

  @override
  Widget build(BuildContext context) {

   return Scaffold(
    body: _pages[_selectedPageIndex],
    bottomNavigationBar: Column(
       mainAxisSize: MainAxisSize.min,
       children: [
        BottomNavigationBar(
          selectedLabelStyle: TextStyle(),
          backgroundColor: Theme.of(context).colorScheme.primary,
           selectedItemColor: Theme.of(context).colorScheme.onSurface,
           currentIndex: _selectedPageIndex,
          type: BottomNavigationBarType.fixed,
           showUnselectedLabels: true,
          onTap: _selectPage,
          items: [
       BottomNavigationBarItem(icon: Icon(Icons.room), label: 'Pokój'),
          BottomNavigationBarItem(icon: Icon(Icons.park), label: 'Zewnątrz'),
          BottomNavigationBarItem(icon: Icon(Icons.fireplace), label: 'Piec'),
        ],)
       ],
    ),
   );
  }

}