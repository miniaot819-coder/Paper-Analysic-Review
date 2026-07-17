class DashboardData {
  const DashboardData({
    required this.totalPublications,
    required this.averageCitationCount,
    required this.mostActiveYear,
    required this.topJournal,
    required this.topAuthor,
    required this.mostInfluentialPaper,
    required this.mostInfluentialPaperCitations,
  });

  final int totalPublications;
  final double averageCitationCount;
  final int mostActiveYear;
  final String topJournal;
  final String topAuthor;
  final String mostInfluentialPaper;
  final int mostInfluentialPaperCitations;
}
