import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dino-game-layout.dart';

void main() {
  runApp(MyApp());
}

Sprite dino = Sprite()
  // basically a placeholder because we do the sprite animations separately
  ..imagePath = "dino/dino_1.png"
  ..imageWidth = 88
  ..imageHeight = 94;

List<GameObject> CACTI = [
  GameObject()
    ..frames = [
      Sprite()
        ..imagePath = "assets/images/cacti/cacti_group.png"
        ..imageWidth = 104
        ..imageHeight = 100,
    ]
    ..collidable = true
    ..frequency = 1,
  GameObject()
    ..frames = [
      Sprite()
        ..imagePath = "assets/images/cacti/cacti_large_1.png"
        ..imageWidth = 50
        ..imageHeight = 100,
    ]
    ..collidable = true
    ..frequency = 1,
  GameObject()
    ..frames = [
      Sprite()
        ..imagePath = "assets/images/cacti/cacti_large_2.png"
        ..imageWidth = 98
        ..imageHeight = 100,
    ]
    ..collidable = true
    ..frequency = 1,
  GameObject()
    ..frames = [
      Sprite()
        ..imagePath = "assets/images/cacti/cacti_small_1.png"
        ..imageWidth = 34
        ..imageHeight = 70,
    ]
    ..collidable = true
    ..frequency = 1,
  GameObject()
    ..frames = [
      Sprite()
        ..imagePath = "assets/images/cacti/cacti_small_2.png"
        ..imageWidth = 68
        ..imageHeight = 70,
    ]
    ..collidable = true
    ..frequency = 1,
  GameObject()
    ..frames = [
      Sprite()
        ..imagePath = "assets/images/cacti/cacti_small_3.png"
        ..imageWidth = 107
        ..imageHeight = 70,
    ]
    ..collidable = true
    ..frequency = 1,
];

GameObject PTERA = GameObject()
  ..frames = [
    Sprite()
      ..imagePath = "assets/images/ptera/ptera_1.png"
      ..imageHeight = 80
      ..imageWidth = 92,
    Sprite()
      ..imagePath = "assets/images/ptera/ptera_2.png"
      ..imageHeight = 80
      ..imageWidth = 92,
  ]
  ..collidable = true
  ..frequency = 5;

GameObject CLOUD = GameObject()
  ..frames = [
    Sprite()
      ..imagePath = "assets/images/cloud.png"
      ..imageHeight = 27
      ..imageWidth = 92,
  ]
  ..collidable = false
  ..frequency = 1;

const int GRAVITY_PPSPS = 2000;
const double RUN_SPEED_ACC_PPSPS = .2;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum DinoState {
  running,
  jumping,
  dead,
  standing,
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  AnimationController worldController;
  int dinoFrame = 1;
  double dinoY = 0;
  double dinodY = 0;
  int lastUpdateCallMillis = 0;
  bool jumpButtonHeld = false;
  Random rand = Random();

  List<PlacedObject> obstacles;

  List<PlacedObject> scenery;

  double runDistance = 0;
  double runSpeed = 30;
  DinoState dinoState = DinoState.standing;
  double best = 0;

  @override
  void initState() {
    super.initState();
    worldController =
        AnimationController(vsync: this, duration: Duration(days: 99));

    worldController.addListener(_update);

    _reset();
  }

  void _update() {
    if (!worldController.isAnimating) {
      return;
    }
    int currentElapsedTimeMillis =
        worldController.lastElapsedDuration.inMilliseconds;
    double elapsedSeconds =
        ((currentElapsedTimeMillis - lastUpdateCallMillis) / 1000);

    runDistance = max(runDistance + runSpeed * elapsedSeconds, 0);
    runSpeed += RUN_SPEED_ACC_PPSPS * elapsedSeconds;

    DinoGameLayout layout = DinoGameLayout(MediaQuery.of(context).size);

    dinoY = max(dinoY + dinodY * elapsedSeconds, 0);
    if (dinoY > 0 && !jumpButtonHeld) {
      dinodY -= GRAVITY_PPSPS * elapsedSeconds;
    }
    if (dinoY <= 0) {
      dinoState = DinoState.running;
    }

    for (PlacedObject obstacle in obstacles) {
      Rect obstacleRect = layout.getObstacleRect(obstacle, runDistance);
      Rect dinoRect = layout.getDinoRect(dinoY);
      if (dinoRect.deflate(15).overlaps(obstacleRect.deflate(15))) {
        _die();
      }
      if (obstacleRect.right < 0) {
        setState(() {
          obstacles.remove(obstacle);
          if (runDistance < 200) {
            obstacles.add(PlacedObject()
              ..location = Offset(runDistance + rand.nextInt(100) + 50, 0)
              ..object = CACTI[rand.nextInt(CACTI.length)]);
          } else {
            if (rand.nextDouble() > .5) {
              obstacles.add(PlacedObject()
                ..location = Offset(runDistance + rand.nextInt(100) + 50, 0)
                ..object = CACTI[rand.nextInt(CACTI.length)]);
            } else {
              obstacles.add(PlacedObject()
                ..location = Offset(runDistance + rand.nextInt(100) + 100,
                    rand.nextInt(100).toDouble())
                ..object = PTERA);
            }
          }
        });
      }
    }

    for (PlacedObject sceneObject in scenery) {
      Rect cloudRect = layout.getCloudRect(sceneObject, runDistance);
      if (cloudRect.right < 0) {
        setState(() {
          scenery.remove(sceneObject);
          scenery.add(
            PlacedObject()
              ..location = Offset(runDistance + rand.nextInt(200) + 200,
                  rand.nextInt(100) - 10.0)
              ..object = CLOUD,
          );
        });
      }
    }

    switch (dinoState) {
      case DinoState.dead:
        dinoFrame = 6;
        break;
      case DinoState.running:
        dinoFrame = (currentElapsedTimeMillis / 100).floor() % 2 + 3;
        break;
      case DinoState.jumping:
        dinoFrame = 1;
        break;
      case DinoState.standing:
        dinoFrame = 1;
        break;
    }

    lastUpdateCallMillis = currentElapsedTimeMillis;
  }

  void _reset() {
    setState(() {
      if (runDistance > best) {
        best = runDistance;
      }
      runDistance = 0;
      dinoState = DinoState.standing;
      dinoFrame = 1;
      dinoY = 0.0;
      dinodY = 0.0;
      obstacles = [
        PlacedObject()
          ..location = Offset(200, 0)
          ..object = CACTI[0],
      ];

      scenery = [
        PlacedObject()
          ..location = Offset(10, 0)
          ..object = CLOUD,
        PlacedObject()
          ..location = Offset(200, 0)
          ..object = CLOUD,
        PlacedObject()
          ..location = Offset(500, 0)
          ..object = CLOUD,
      ];
    });
  }

  void _jump() {
    if ([DinoState.standing, DinoState.running].contains(dinoState)) {
      if (!worldController.isAnimating) {
        worldController.forward(from: 0);
      }
      setState(() {
        jumpButtonHeld = true;
        dinodY = 650;
        dinoState = DinoState.jumping;
        dinoFrame = 1;
        dinoY = .01;
      });
      Timer(Duration(milliseconds: 200), _cancelJump);
    }
  }

  void _die() {
    setState(() {
      worldController.stop();
      dinoState = DinoState.dead;
    });
  }

  void _cancelJump() {
    setState(() {
      jumpButtonHeld = false;
    });
  }

  String _buttonText() {
    switch (dinoState) {
      case DinoState.running:
      case DinoState.jumping:
        return "Jump";
      case DinoState.dead:
        return "Reset";
      case DinoState.standing:
        return "Start";
      default:
        return "Jump";
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    DinoGameLayout layout = DinoGameLayout(screenSize);
    List<Widget> children = [
      AnimatedBuilder(
          animation: worldController,
          child: Image.asset(
            "assets/images/scenery.png",
            fit: BoxFit.cover,
          ),
          builder: (context, child) {
            return Positioned(
              bottom: screenSize.height / 3,
              left: -((runDistance * 10) % 2400),
              height: 20,
              child: child,
            );
          }),
      AnimatedBuilder(
          animation: worldController,
          child: Image.asset(
            "assets/images/scenery.png",
            fit: BoxFit.cover,
          ),
          builder: (context, child) {
            return Positioned(
              bottom: screenSize.height / 3,
              left: -((runDistance * 10) % 2400) + 2400 - screenSize.width,
              height: 20,
              child: child,
            );
          }),
      AnimatedBuilder(
          animation: worldController,
          builder: (context, child) {
            return Positioned(
              right: 0,
              left: 0,
              top: 0,
              height: screenSize.height / 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text("${runDistance.floor()}",
                      style: GoogleFonts.vt323(fontSize: 36)),
                ],
              ),
            );
          }),
    ];
    for (PlacedObject sceneObject in scenery) {
      children.add(
        AnimatedBuilder(
            animation: worldController,
            child: Image.asset(
              sceneObject
                  .object
                  .frames[worldController.isAnimating
                      ? (worldController.lastElapsedDuration.inMilliseconds /
                                  1000 *
                                  sceneObject.object.frequency)
                              .floor() %
                          sceneObject.object.frames.length
                      : 0]
                  .imagePath,
              gaplessPlayback: true,
            ),
            builder: (context, child) {
              Rect obstacleRect = layout.getCloudRect(sceneObject, runDistance);
              return Positioned(
                  top: obstacleRect.top,
                  left: obstacleRect.left,
                  width: obstacleRect.width,
                  height: obstacleRect.height,
                  child: child);
            }),
      );
    }
    for (PlacedObject obstacle in obstacles) {
      children.add(
        AnimatedBuilder(
            animation: worldController,
            builder: (context, child) {
              Rect obstacleRect = layout.getObstacleRect(obstacle, runDistance);
              return Positioned(
                  top: obstacleRect.top,
                  left: obstacleRect.left,
                  width: obstacleRect.width,
                  height: obstacleRect.height,
                  child: Image.asset(
                    obstacle
                        .object
                        .frames[worldController.isAnimating
                            ? (worldController.lastElapsedDuration
                                            .inMilliseconds /
                                        1000 *
                                        obstacle.object.frequency)
                                    .floor() %
                                obstacle.object.frames.length
                            : 0]
                        .imagePath,
                    gaplessPlayback: true,
                  ));
            }),
      );
    }
    children.add(AnimatedBuilder(
        animation: worldController,
        builder: (context, child) {
          Rect dinoRect = layout.getDinoRect(dinoY);
          return Positioned(
            left: dinoRect.left,
            top: dinoRect.top,
            width: dinoRect.width,
            height: dinoRect.height,
            child: Image.asset(
              "assets/images/dino/dino_${dinoFrame}.png",
              gaplessPlayback: true,
            ),
          );
        }));

    if (dinoState == DinoState.dead) {
      children.add(Align(
        alignment: Alignment(0, -.5),
        child: Text("GAME OVER", style: GoogleFonts.vt323(fontSize: 48)),
      ));
    }

    children.add(Positioned(
        bottom: 20,
        left: 40,
        right: 40,
        height: screenSize.height / 4,
        child: GestureDetector(
            onTapDown: (_) {
              if (dinoState != DinoState.dead) {
                _jump();
              }
            },
            onTap: () {
              if (dinoState == DinoState.dead) {
                _reset();
              }
            },
            onTapUp: (_) {
              if (dinoState != DinoState.dead) {
                _cancelJump();
              }
            },
            child: InkWell(
              child: Ink(
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                      child: Text(_buttonText(),
                          style: GoogleFonts.vt323(fontSize: 48)))),
            ))));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: children,
        ),
      ),
    );
  }
}
