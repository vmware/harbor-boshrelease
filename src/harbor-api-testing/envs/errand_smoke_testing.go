package envs

//ConcourseCILdapEnv : Ldap env for concourse pipeline
var ErrandSmokeTestEnv = Environment{
	Protocol:       "https",
	TestingProject: "errandsmoketest",
	ImageName:      "busybox",
	ImageTag:       "latest",
	CAFile:         "../../../ca.crt",
	KeyFile:        "../../../key.crt",
	CertFile:       "../../../cert.crt",
	Account:        "admin",
	Password:       "pksxgxmifc0cnwa5px9h",
	Admin:          "admin",
	AdminPass:      "pksxgxmifc0cnwa5px9h",
	Hostname:       "10.112.122.1",
}
