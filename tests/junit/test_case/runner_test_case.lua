local M = {}

function M.test_id_to_neotest_id()
	local path = '/home/username/'
	local mock_uri = 'file:/' .. path .. 'PetControllerTests.java'

	return {
		{
			input = {
				id = 'spring-petclinic@org.springframework.samples.petclinic.owner.PetControllerTests#testInitCreationForm()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::testInitCreationForm',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests#testProcessCreationFormSuccess()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::testProcessCreationFormSuccess',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests#testProcessUpdateFormSuccess()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::testProcessUpdateFormSuccess',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessCreationFormHasErrors#testInitUpdateForm()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::ProcessCreationFormHasErrors::testInitUpdateForm',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessCreationFormHasErrors#testProcessCreationFormWithBlankName()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::'
				.. 'PetControllerTests::'
				.. 'ProcessCreationFormHasErrors::'
				.. 'testProcessCreationFormWithBlankName',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessCreationFormHasErrors#testProcessCreationFormWithInvalidBirthDate()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::'
				.. 'PetControllerTests::'
				.. 'ProcessCreationFormHasErrors::'
				.. 'testProcessCreationFormWithInvalidBirthDate',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessCreationFormHasErrors#testProcessCreationFormWithMissingPetType()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::'
				.. 'PetControllerTests::'
				.. 'ProcessCreationFormHasErrors::'
				.. 'testProcessCreationFormWithMissingPetType',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessCreationFormHasErrors',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::ProcessCreationFormHasErrors',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessUpdateFormHasErrors#testProcessUpdateFormWithBlankName()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::ProcessUpdateFormHasErrors::testProcessUpdateFormWithBlankName',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessUpdateFormHasErrors#testProcessUpdateFormWithInvalidBirthDate()',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::'
				.. 'ProcessUpdateFormHasErrors::'
				.. 'testProcessUpdateFormWithInvalidBirthDate',
		},
		{
			input = {
				id = 'spring-petclinic@'
					.. 'org.springframework.samples.petclinic.owner.PetControllerTests$'
					.. 'ProcessUpdateFormHasErrors',
				uri = mock_uri,
			},
			expected = path
				.. 'PetControllerTests.java::PetControllerTests::ProcessUpdateFormHasErrors',
		},
		{
			input = {
				id = 'spring-petclinic@org.springframework.samples.petclinic.owner.PetControllerTests',
				uri = mock_uri,
			},
			expected = path .. 'PetControllerTests.java::PetControllerTests',
		},
		{
			input = {
				id = 'spring-petclinic@com.mock.PetControllerTests#testApp',
				uri = mock_uri,
				testKind = 1,
			},
			expected = path .. 'PetControllerTests.java::PetControllerTests::testApp',
		},
	}
end

return M
