import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_watch_os_connectivity/flutter_watch_os_connectivity.dart';
import 'package:pong/constant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moving Ball',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Position de la balle
  double ballY = 0.0;
  double ballX = 0.0;

  // Vitesse de la balle
  double speedY = 0.0; // Vitesse initiale à 0
  double speedX = 0.0;

  // Position de la barre
  double paddleX = 0.0;

  bool isPlaying = false;
  late Timer gameTimer;

  int score = 0;

  void startGame() {
    if (!isPlaying) {
      isPlaying = true;
      sendGameStateToWatch(isPlaying);

      setState(() {
        ballY = 0.0;
        ballX = 0.0;
        paddleX = 0.0;
        speedY = initialSpeedY; // On commence avec une vitesse vers le haut
        speedX = (math.Random().nextDouble() - 0.5) * 2.0;
      });

      gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (isPlaying) {
          updateGame();
        }
      });
    }
  }

  void updateGame() {
    setState(() {
      // Appliquer la gravité à la vitesse verticale
      speedY += gravity;

      // Mise à jour des positions
      ballY += speedY / 100;
      ballX += speedX / 100;

      // Rebond sur les murs latéraux
      if (ballX > 1.0 || ballX < -1.0) {
        speedX = -speedX * bounceEnergy;
        ballX = ballX.clamp(-1.0, 1.0);
      }

      // Rebond sur le haut de l'écran
      if (ballY < -1.0) {
        speedY = -speedY * bounceEnergy;
        ballY = -1.0;
      }

      // Vérification de collision avec la barre
      if (checkCollision()) {
        score += 1;
        sendScoreToWatch(score);
        onCollision();
      }

      // Vérification si la balle est tombée
      if (ballY > 1) {
        stopGame();
      }

      print("BAlle Y ===============$ballY");
    });
  }

  void stopGame() {
    isPlaying = false;
    sendGameStateToWatch(isPlaying);
    sendScoreToWatch(0);
    gameTimer.cancel();
    setState(() {
      ballY = 0.0;
      ballX = 0.0;
      paddleX = 0.0;
      score = 0;
    });
  }

  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (isPlaying) {
      setState(() {
        double newPaddleX = paddleX +
            (details.delta.dx / (MediaQuery.of(context).size.width / 2));
        double paddleWidthNormalized =
            paddleWidth / MediaQuery.of(context).size.width;
        paddleX = newPaddleX.clamp(
            -1.0 + paddleWidthNormalized, 1.0 - paddleWidthNormalized);
      });
    }
  }

  bool checkCollision() {
    // Convertir la largeur de la barre en coordonnées normalisées
    double normalizedPaddleWidth =
        paddleWidth / MediaQuery.of(context).size.width;

    // Vérifier si la balle est à la hauteur de la barre
    if (ballY >= paddleY - 0.02 && speedY > 0) {
      // Ajout de la condition speedY > 0
      // Vérifier si la balle est dans la largeur de la barre
      return (ballX >= (paddleX - normalizedPaddleWidth) &&
          ballX <= (paddleX + normalizedPaddleWidth));
    }
    return false;
  }

  void onCollision() {
    // Calculer la vitesse résultante après le rebond
    double speed = math.sqrt(speedX * speedX + speedY * speedY);

    // Calculer l'angle de rebond basé sur la position de l'impact
    double hitPosition =
        (ballX - paddleX) / (paddleWidth / MediaQuery.of(context).size.width);
    double angle = hitPosition * (math.pi / 4); // Max 45 degrés

    // Appliquer le nouveau vecteur de vitesse
    speedY = -speed * math.cos(angle) * bounceEnergy;
    speedX = speed * math.sin(angle) * bounceEnergy;

    // Placer la balle juste au-dessus de la barre
    ballY = paddleY - 0.02;
  }

  FlutterWatchOsConnectivity _flutterWatchOsConnectivity =
      FlutterWatchOsConnectivity();
  @override
  void initState() {
    //initWatchConnectivity();
    initWatchConnectivity();
    super.initState();
  }

  void initWatchConnectivity() {
    _flutterWatchOsConnectivity.configureAndActivateSession();
    _flutterWatchOsConnectivity.activationStateChanged
        .listen((activationState) {
      print("==========activationState==========$activationState");
      if (activationState == ActivationState.activated) {
        // Continue to use the plugin
      } else {
        // Do something in this case
      }
    });
    _flutterWatchOsConnectivity.messageReceived.listen((message) async {
      final currentMessage = message.data;

      print("===============currentMessage ==============$currentMessage");

      // Vérifier si c'est un message de contrôle du paddle
      if (currentMessage['method'] == 'movePaddle') {
        handleWatchControl(currentMessage['data']['direction']);
      }
    });
  }

  void handleWatchControl(String direction) {
    if (!isPlaying) return;

    setState(() {
      // Calculer la nouvelle position
      double newPaddleX = paddleX;
      if (direction == 'left') {
        newPaddleX -= paddleStep;
      } else if (direction == 'right') {
        newPaddleX += paddleStep;
      }

      // Appliquer les limites comme dans onHorizontalDragUpdate
      double paddleWidthNormalized =
          paddleWidth / MediaQuery.of(context).size.width;
      paddleX = newPaddleX.clamp(
          -1.0 + paddleWidthNormalized, 1.0 - paddleWidthNormalized);
    });
  }

  // Envoyer le score à l'Apple Watch
  void sendScoreToWatch(int score) {
    _flutterWatchOsConnectivity
        .sendMessage({'method': 'updateScore', 'data': score});
  }

  // Envoyer l'état du jeu
  void sendGameStateToWatch(bool isPlaying) {
    _flutterWatchOsConnectivity
        .sendMessage({'method': 'gameState', 'data': isPlaying});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTapDown: (_) {
          if (!isPlaying) {
            startGame();
          }
        },
        onHorizontalDragUpdate: onHorizontalDragUpdate,
        child: Container(
          color: Colors.black,
          child: CustomPaint(
              painter: GamePainter(
                ballY: ballY,
                ballX: ballX,
                paddleX: paddleX,
                paddleWidth: paddleWidth,
                paddleHeight: paddleHeight,
                paddleY: paddleY,
              ),
              child: Container(
                width: double.infinity,
                child: !isPlaying
                    ? Center(
                        child: const Text(
                          'Tapez pour commencer\nGlissez pour déplacer la barre ou utilisez votre Apple Watch appairée',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          SizedBox(
                            height: kToolbarHeight,
                          ),
                          Text('$score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 54,
                              )),
                        ],
                      ),
              )),
        ),
      ),
    );
  }
}

class GamePainter extends CustomPainter {
  final double ballY;
  final double ballX;
  final double paddleX;
  final double paddleWidth;
  final double paddleHeight;
  final double paddleY;
  static const double ballSize = 20;

  GamePainter({
    required this.ballY,
    required this.ballX,
    required this.paddleX,
    required this.paddleWidth,
    required this.paddleHeight,
    required this.paddleY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner la balle
    final ballPaint = Paint()..color = Colors.white;
    final ballPosition = Offset(
      size.width / 2 + (ballX * size.width / 2),
      ballY * size.height,
    );
    canvas.drawCircle(ballPosition, ballSize / 2, ballPaint);

    // Dessiner la barre
    final paddlePaint = Paint()..color = Colors.blue;
    final paddleRect = Rect.fromCenter(
      center: Offset(
        size.width / 2 + (paddleX * size.width / 2),
        paddleY * size.height,
      ),
      width: paddleWidth,
      height: paddleHeight,
    );
    canvas.drawRect(paddleRect, paddlePaint);
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return oldDelegate.ballY != ballY ||
        oldDelegate.ballX != ballX ||
        oldDelegate.paddleX != paddleX;
  }
}
