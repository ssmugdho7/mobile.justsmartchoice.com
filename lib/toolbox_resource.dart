class ToolboxResource {
  const ToolboxResource(this.title, this.url, this.description);
  final String title, url, description;
  static ToolboxResource? find(Uri uri) {
    for (final resource in resources) {
      final candidate = Uri.parse(resource.url);
      if (candidate.host == uri.host && candidate.path == uri.path) {
        return resource;
      }
    }
    return null;
  }

  static const resources = [
    ToolboxResource(
      "Construction Pros Insurance",
      "https://constructionprosins.com/",
      "Phone: 800-685-0027 · Florida contractor insurance, general liability, workers’ compensation, bonds, and commercial auto.",
    ),
    ToolboxResource(
      "Simply Business",
      "https://www.simplybusiness.com/business-insurance/workers-compensation-insurance/florida/",
      "Phone: 844-654-7272 · Workers’ compensation and business insurance quote support for Florida businesses.",
    ),
    ToolboxResource(
      "Progressive Commercial",
      "https://www.progressivecommercial.com/",
      "Phone: 1-888-806-9598 · Commercial auto, business insurance, quote support, and contractor vehicle coverage.",
    ),
    ToolboxResource(
      "The Hartford Contractor Insurance",
      "https://www.thehartford.com/business-insurance/contractor",
      "Quote: 855-440-1078 · Business service: 866-467-8730 · Contractor liability and construction insurance options.",
    ),
    ToolboxResource(
      "FWCJUA",
      "https://www.fwcjua.com/",
      "Phone: 941-378-7400 · Florida Workers’ Compensation Joint Underwriting Association for difficult-to-place work comp coverage.",
    ),
    ToolboxResource(
      "TrustedChoice.com",
      "https://www.trustedchoice.com/",
      "Independent insurance agent network for contractor coverage, business insurance, liability, auto, and specialty policies.",
    ),
    ToolboxResource(
      "OSHA Construction Outreach Training",
      "https://www.osha.gov/training/outreach/construction",
      "Official OSHA information for construction industry OSHA 10-hour and 30-hour outreach training.",
    ),
    ToolboxResource(
      "OSHA Authorized Online Providers",
      "https://www.osha.gov/training/outreach/training-providers",
      "Official list of OSHA-authorized online outreach training providers for construction safety courses.",
    ),
    ToolboxResource(
      "USF OSHA Training Institute",
      "https://health.usf.edu/publichealth/research/otiec/",
      "Florida OSHA-authorized safety training, certification courses, and construction safety education.",
    ),
    ToolboxResource(
      "ABC Central Florida Safety Training",
      "https://abccentralflorida.com/safety/safety-training/",
      "Construction safety training, OSHA 10-hour outreach, supervisor safety, and contractor education.",
    ),
    ToolboxResource(
      "CareerSafe OSHA 10 Construction",
      "https://www.careersafeonline.com/courses/osha-10-hour/construction",
      "Entry-level construction safety training for hazard recognition, worker rights, and employer responsibilities.",
    ),
    ToolboxResource(
      "OSHA.com / 360training",
      "https://www.osha.com/",
      "Online OSHA outreach, HAZWOPER, construction safety, and general safety training courses.",
    ),
    ToolboxResource(
      "Florida Payment Forms",
      "https://www.levelset.com/construction-payment-resources/florida-forms/",
      "Florida preliminary notice, lien waiver, mechanics lien, and payment document resources.",
    ),
    ToolboxResource(
      "Construction Change Order Sample",
      "https://www.seminolecountyfl.gov/docs/default-source/pdf/construction-forms-exhibit-to-agreement.pdf",
      "Public construction form packet with change order and waiver examples.",
    ),
    ToolboxResource(
      "Lien Waiver Template",
      "https://legaltemplates.net/form/mechanics-lien/lien-waiver/",
      "Sample lien waiver form for construction payment documentation.",
    ),
  ];
}
