namespace ZoozyApi.Dtos
{
    public class UpdateAgreementsRequest
    {
        public int UserId { get; set; }
        public bool TermsAccepted { get; set; }
        public bool PrivacyAccepted { get; set; }
    }
}
