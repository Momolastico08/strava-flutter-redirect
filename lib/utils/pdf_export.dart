// 📦 Rapport PDF enrichi avec graphique nutrition, poids, tableau muscu, sommeil, hydratation, signature et envoi
import 'dart:typed_data';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

Future<Uint8List> generateQrImage(String data) async {
  final painter = QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: false,
    color: const Color(0xFF000000),
    emptyColor: const Color(0xFFFFFFFF),
  );
  final picData = await painter.toImageData(200);
  return picData!.buffer.asUint8List();
}

Future<XFile?> askUserForPhoto(BuildContext context) async {
  return await showDialog<XFile?>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Ajouter une photo ?"),
      content: const Text("Souhaites-tu inclure une photo de progression dans le rapport ?"),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.camera_alt),
          label: const Text("Caméra"),
          onPressed: () async {
            final image = await ImagePicker().pickImage(source: ImageSource.camera);
            Navigator.pop(context, image);
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.photo_library),
          label: const Text("Galerie"),
          onPressed: () async {
            final image = await ImagePicker().pickImage(source: ImageSource.gallery);
            Navigator.pop(context, image);
          },
        ),
        TextButton(
          child: const Text("Ignorer"),
          onPressed: () => Navigator.pop(context, null),
        ),
      ],
    ),
  );
}

Future<void> generateWeeklyReportPdf({
  required BuildContext context,
  required double avgCalories,
  required double avgProteins,
  required int hydration,
  required int workoutCount,
  required double volume,
  required int weight,
  required double height,
  String objectif = 'Prise de masse',
  double avgSleep = 0,
  List<double> hydrationHistory = const [0, 0, 0, 0, 0, 0, 0],
  List<double> weightHistory = const [70, 70, 70, 70, 70, 70, 70],
  List<double> calorieHistory = const [0, 0, 0, 0, 0, 0, 0],
  List<double> proteinHistory = const [0, 0, 0, 0, 0, 0, 0],
  Map<String, List<double>> muscleProgress = const {},
}) async {
  final pdf = pw.Document();
  final now = DateTime.now();
  final formatter = DateFormat('dd/MM/yyyy');
  final dataDays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  double score = 0;
  if (avgCalories >= 1800) score += 25;
  if (avgProteins >= 1.5 * weight) score += 20;
  if (hydration >= weight * 35) score += 15;
  if (workoutCount >= 3) score += 25;
  if (avgSleep >= 7) score += 15;

  String getUserLevel() {
    if (score >= 80) return "Athlète 🔥";
    if (score >= 50) return "Intermédiaire 💪";
    return "Débutant 🏁";
  }

  final qrBytes = await generateQrImage("https://muscu-tracker.app");
  final qrImage = pw.MemoryImage(qrBytes);

  pw.MemoryImage? photo;
  final pickedFile = await askUserForPhoto(context);
  if (pickedFile != null) {
    final photoBytes = await pickedFile.readAsBytes();
    photo = pw.MemoryImage(photoBytes);
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (pw.Context context) => [
        pw.Text('📊 Rapport Hebdomadaire – Muscu Tracker', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text("Semaine du ${formatter.format(now.subtract(const Duration(days: 6)))} au ${formatter.format(now)}"),
        pw.SizedBox(height: 10),
        pw.Text("🎯 Objectif déclaré : $objectif", style: pw.TextStyle(fontSize: 14, color: PdfColors.blue)),
        pw.SizedBox(height: 16),
        pw.Text("⭐ Score global : ${score.toStringAsFixed(0)} / 100 — Niveau : ${getUserLevel()}", style: pw.TextStyle(fontSize: 14)),

        pw.SizedBox(height: 16),
        pw.Text("📈 Graphique nutritionnel (calories & protéines)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          height: 200,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(dataDays, margin: 12),
              yAxis: pw.FixedAxis([0, 1000, 2000, 3000]),
            ),
            datasets: [
              pw.LineDataSet(
                  legend: 'Calories',
                  color: PdfColors.orange,
                  data: List.generate(7, (i) => pw.PointChartValue(i.toDouble(), calorieHistory[i]))
              ),
              pw.LineDataSet(
                  legend: 'Protéines',
                  color: PdfColors.blue,
                  data: List.generate(7, (i) => pw.PointChartValue(i.toDouble(), proteinHistory[i]))
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 16),
        pw.Text("📉 Évolution du poids", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          height: 200,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(dataDays, margin: 12),
              yAxis: pw.FixedAxis([
                (weightHistory.reduce((a, b) => a < b ? a : b) - 2).floorToDouble(),
                (weightHistory.reduce((a, b) => a + b) / weightHistory.length).roundToDouble(),
                (weightHistory.reduce((a, b) => a > b ? a : b) + 2).ceilToDouble()
              ]),
            ),
            datasets: [
              pw.LineDataSet(
                legend: 'Poids (kg)',
                color: PdfColors.green,
                data: List.generate(7, (i) => pw.PointChartValue(i.toDouble(), weightHistory[i])),
              )
            ],
          ),
        ),

        pw.SizedBox(height: 16),
        pw.Text("💧 Hydratation quotidienne", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Container(
          height: 200,
          child: pw.Chart(
            grid: pw.CartesianGrid(
              xAxis: pw.FixedAxis.fromStrings(dataDays, margin: 12),
              yAxis: pw.FixedAxis([0, 1000, 2000, 3000, 4000]),
            ),
            datasets: [
              pw.LineDataSet(
                legend: 'Hydratation (ml)',
                color: PdfColors.teal,
                data: List.generate(7, (i) => pw.PointChartValue(i.toDouble(), hydrationHistory[i])),
              )
            ],
          ),
        ),

        pw.SizedBox(height: 16),
        pw.Text("📊 Tableau de progression musculation", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Table.fromTextArray(
          headers: ["Groupe", "S1", "S2", "S3", "S4", "S5", "S6"],
          data: muscleProgress.entries.map((e) => [e.key, ...e.value.map((v) => v.toStringAsFixed(0))]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.centerLeft,
        ),

        if (photo != null) ...[
          pw.SizedBox(height: 30),
          pw.Text("📸 Photo de progression", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          pw.Image(photo, height: 200),
          pw.SizedBox(height: 20),
        ],

        pw.SizedBox(height: 16),
        pw.Text("🛌 Sommeil moyen", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text("Votre durée moyenne de sommeil cette semaine est de ${avgSleep.toStringAsFixed(1)} heures."),

        pw.SizedBox(height: 16),
        pw.Text("🤖 Recommandations IA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Bullet(text: avgCalories < 1800 ? "Augmentez vos apports caloriques pour soutenir la progression." : "Apports caloriques adaptés."),
        pw.Bullet(text: avgProteins < 1.5 * weight ? "Renforcez votre apport en protéines." : "Apport protéique optimal."),
        pw.Bullet(text: hydration < weight * 35 ? "Buvez davantage d’eau pour rester bien hydraté." : "Hydratation satisfaisante."),
        pw.Bullet(text: workoutCount < 3 ? "Essayez d’avoir au moins 3 séances par semaine." : "Bonne régularité d'entraînement."),
        pw.Bullet(text: avgSleep < 7 ? "Veillez à dormir au moins 7h par nuit." : "Sommeil suffisant."),

        pw.SizedBox(height: 16),
        pw.Text("📋 Résumé des moyennes", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Bullet(text: "Calories moyennes : ${avgCalories.toStringAsFixed(0)} kcal/jour"),
        pw.Bullet(text: "Protéines moyennes : ${avgProteins.toStringAsFixed(1)} g/jour"),
        pw.Bullet(text: "Hydratation moyenne : ${(hydrationHistory.reduce((a, b) => a + b) / hydrationHistory.length).toStringAsFixed(0)} ml/jour"),
        pw.Bullet(text: "Sommeil moyen : ${avgSleep.toStringAsFixed(1)} h/nuit"),

        pw.SizedBox(height: 16),
        pw.Text("🎯 Objectifs pour la semaine prochaine", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text("(à remplir manuellement)", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        pw.Container(
          height: 80,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
        ),

        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Généré avec 💪 par Muscu Tracker", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                pw.Text("${formatter.format(now)}", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ],
            ),
            pw.Image(qrImage, width: 60),
          ],
        )
      ],
    ),
  );

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/rapport_muscu_${now.millisecondsSinceEpoch}.pdf");
  await file.writeAsBytes(await pdf.save());
  await Share.shareXFiles([XFile(file.path)], subject: "Mon rapport Muscu Tracker");
}