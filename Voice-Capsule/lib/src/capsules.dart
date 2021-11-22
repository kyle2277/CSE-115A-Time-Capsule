import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'playback.dart';
import 'voice_capsule.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';

import 'utils.dart';
import 'voice_capsule.dart';

/*
 * Capsules page
 */

// Capsules Slide
// The page to open capsules
class CapsulesSlide extends StatefulWidget {
  const CapsulesSlide({Key? key}) : super(key: key);

  @override
  _CapsulesSlideState createState() => _CapsulesSlideState();
}


class _CapsulesSlideState extends State<CapsulesSlide>{
  // List of available capsules
  List<VoiceCapsule> capsules = [];

  // Initially load capsules from local .dat files
  Future<void> loadCapsules() async {
    Directory dir = Directory(CAPSULES_DIRECTORY);
    for(var entity in dir.listSync(recursive: false)) {
      if(entity is File) {
        String fileName = basename(entity.path);
        String fileNameSplit = fileName.split('.').last;
        if(fileNameSplit == "data") {
          await VoiceCapsule.newCapsuleFromDataFile(entity.path).then((loadedCapsule) {
            if(loadedCapsule != null) {
              print("Loading capsule: ${loadedCapsule.localFileName}");
              if(!capsules.contains(loadedCapsule)) {
                setState(() {
                  capsules.insert(0, loadedCapsule);
                });
              }
            }
          });
        }
      }
    }
  }

  @override
  @mustCallSuper
  void initState() {
    loadCapsules();
    super.initState();
  }

  // Check if any capsules available, if so download from database
  Future<void> checkForNewCapsules(BuildContext context) async {
    String myUID = FirebaseAuth.instance.currentUser!.uid;
    showToast_OK(context, "Loading...", duration:10000);
    await VoiceCapsule.checkForCapsules(myUID).then((pendingCapsules) async {
      if(pendingCapsules.isEmpty) {
        print("No available capsules");
        showToast_quick(context, "No new voice capsules", duration: 2);
        return;
      }
      bool modified = false;
      for(VoiceCapsule newCapsule in pendingCapsules) {
        print("Available Capsule:");
        print("Sender UID: ${newCapsule.senderUID}");
        print("Storage file path: ${newCapsule.firebaseStoragePath}");
        print("Local file name: ${newCapsule.localFileName}");
        print("Open Date/Time: ${newCapsule.openDateTime}");
        await newCapsule.fetchFromDatabase().then((success) {
          if(success) {
            modified = true;
            // add to list of capsules
            setState(() {
              capsules.insert(0, newCapsule);
            });
          }
        });
      }
      if(modified) {
        showToast_quick(context, "New voice capsules received!", duration: 3);
      } else {
        showToast_quick(context, "No new voice capsules", duration: 2);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  Widget build(BuildContext context) {
    return Column (
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded (
          child: ListView.builder(
            itemCount: capsules.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title:Text(capsules[index].toString()),
                  onTap : () {
                    Navigator.push(
                      context,
                      // Send audio file to player using capsules[index]
                      MaterialPageRoute(builder: (context) => const PlaybackScreen()),
                    );
                  }
                )
              );
            },
          ),
        ),
        RaisedButton(
          onPressed: () async {
            await checkForNewCapsules(context).then((value) {
            });
          },
          color: Colors.grey[300],
          highlightColor: Colors.grey[300],
          child: Text("Refresh"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ]
    );
  }
}

// Page to send recording and other options
class PlaybackScreen extends StatelessWidget {
  const PlaybackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Play Recording"),
        centerTitle: true,
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: Column (
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SimplePlayback(audioFileUrl: 'recorded_file.mp4',),
          ],
        ),
      ),
    );
  }
}
