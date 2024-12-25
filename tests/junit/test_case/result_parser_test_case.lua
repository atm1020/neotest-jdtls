local M = {}

M.test_cases_junit5 = {
	{
		input = '%TSTTREE18,provideArguments(dev.sirosh.case_folders.CaseFolderSourceArgumentsProviderTest),'
			.. 'false,1,true,3,two param test,java.lang.reflect.Method\\, java.util.List,[engine:junit-jupiter]/'
			.. '[class:dev.sirosh.case_folders.CaseFolderSourceArgumentsProviderTest]/'
			.. '[test-template:provideArguments(java.lang.reflect.Method\\, java.util.List)]/[test-template-invocation:#15]',
		expected = {
			display_name = 'two param test',
			is_dynamic_test = true,
			is_suite = false,
			parameter_types = 'java.lang.reflect.Method\\, java.util.List',
			parent_id = 3,
			test_count = 1,
			test_id = 18,
			test_name = 'provideArguments(dev.sirosh.case_folders.CaseFolderSourceArgumentsProviderTest)',
			unique_id = '[engine:junit-jupiter]/'
				.. '[class:dev.sirosh.case_folders.CaseFolderSourceArgumentsProviderTest]/'
				.. '[test-template:provideArguments(java.lang.reflect.Method\\, java.util.List)]/'
				.. '[test-template-invocation:#15]',
		},
	},
}

function M.get_test_id_for_junit_5method(project_name)
	return {
		{
			input = '[engine:junit-jupiter]/'
				.. '[class:org.springframework.samples.petclinic.owner.PetControllerTests]/'
				.. '[nested-class:ProcessCreationFormHasErrors]/'
				.. '[method:testProcessCreationFormWithBlankName()]',
			expected = project_name
				.. '@org.springframework.samples.petclinic.owner.PetControllerTests$'
				.. 'ProcessCreationFormHasErrors#testProcessCreationFormWithBlankName()',
		},
		{
			input = '[engine:junit-jupiter]/'
				.. '[class:org.springframework.samples.petclinic.owner.PetControllerTests]/'
				.. '[method:testProcessCreationFormSuccess()]',
			expected = project_name
				.. '@org.springframework.samples.petclinic.owner.PetControllerTests#testProcessCreationFormSuccess()',
		},
	}
end

M.get_junit5_method_name = {
	-- simple
	{
		input = 'methodName(java.lang.String,java.lang.String)',
		expected = 'methodName(String,String)',
	},
	{
		input = 'methodName(java.lang.String, java.lang.String,java.lang.Long)',
		expected = 'methodName(String,String,Long)',
	},
	-- Object[]
	{
		input = 'methodName(%5BLjava.lang.Byte;)',
		expected = 'methodName(Byte[])',
	},
	{
		input = 'methodName(%5BLjava.lang.String;)',
		expected = 'methodName(String[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Integer;)',
		expected = 'methodName(Integer[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Long;)',
		expected = 'methodName(Long[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Float;)',
		expected = 'methodName(Float[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Double;)',
		expected = 'methodName(Double[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Short;)',
		expected = 'methodName(Short[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Character;)',
		expected = 'methodName(Character[])',
	},
	{
		input = 'methodName(%5BLjava.lang.Boolean;)',
		expected = 'methodName(Boolean[])',
	},
	-- primitive[]
	{
		input = 'methodName(%5BZ)',
		expected = 'methodName(boolean[])',
	},
	{
		input = 'methodName(%5BB)',
		expected = 'methodName(byte[])',
	},
	{
		input = 'methodName(%5BS)',
		expected = 'methodName(short[])',
	},
	{
		input = 'methodName(%5BI)',
		expected = 'methodName(int[])',
	},
	{
		input = 'methodName(%5BJ)',
		expected = 'methodName(long[])',
	},
	{
		input = 'methodName(%5BF)',
		expected = 'methodName(float[])',
	},
	{
		input = 'methodName(%5BD)',
		expected = 'methodName(double[])',
	},
	{
		input = 'methodName(%5BC)',
		expected = 'methodName(char[])',
	},
	{
		input = 'methodName(%5BF, %5BD)',
		expected = 'methodName(float[],double[])',
	},
	-- mixed
	{
		input = 'methodName(java.lang.Integer, %5BLjava.lang.Short;, %5BZ, java.lang.String)',
		expected = 'methodName(Integer,Short[],boolean[],String)',
	},
}

return M
