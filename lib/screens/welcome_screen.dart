import 'package:flutter/material.dart';
import 'package:project050925/screens/login_screen.dart';
import 'package:project050925/screens/register_screen.dart';

class StudentCalculatorApp extends StatelessWidget{
  const StudentCalculatorApp({super.key});


  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget{
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    const baseWidth = 412;
    const baseHeight = 917;

    final scaleW = screenWidth / baseWidth;
    final scaleH = screenHeight / baseHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 40 * scaleH),
              Image.asset(
                'assets/images/welcome_page_photo.png',
                 width: 300 * scaleW,
                 height: 300 * scaleH,
                ),
               SizedBox(height: 10 * scaleH),
               Text(
                 'Aplus \nҚосымшасына \nҚош келдіңіз!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                   fontSize: 30 * scaleW,
                   fontWeight: FontWeight.w400,
                    fontFamily: 'Montserrat',
                   color: Colors.black,
                 ),
               ),
                SizedBox(height: 60 * scaleH),
                SizedBox(
                  width: 325 * scaleW,
                  height: 60 * scaleH,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF2DDBD2),
                     shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100 * scaleW),
                     ),
                      padding: EdgeInsets.symmetric(vertical: 15 * scaleH),
                    ),
                   onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: Text(
                      'Кіру',
                      style: TextStyle(
                        fontSize: 22.5 * scaleW,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Montserrat',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
               SizedBox(height: 15 * scaleH),
                TextButton(
                   onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Text(
                    'Тіркелу',
                   style: TextStyle(
                      fontSize: 22.5 * scaleW,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Montserrat',
                      color: Color(0xFF20409A),
                    ),
                  ),
                ),
                SizedBox(height: 10 * scaleH),
              ],
            ),
          ),
        ),
      );
    }
  }