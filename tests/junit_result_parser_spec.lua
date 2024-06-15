local parser = require('neotest-jdtls.junit_result_parser')
local JunitTestResultState =
	require('neotest-jdtls.junit_result_parser').junit_test_result_state

describe('result_analyzer', function()
	it('test JUnit 4 passed result', function()
		local junit_parser = parser:new()
		junit_parser.lines = {
			'%TESTC  1 v2',
			'%TSTTREE1,shouldPass(junit4.TestAnnotation),false,1,false,-1,shouldPass(junit4.TestAnnotation),,',
			'%TESTS  1,shouldPass(junit4.TestAnnotation)',
			'%TESTE  1,shouldPass(junit4.TestAnnotation)',
			'%RUNTIME15`;',
		}
		junit_parser:parse()
		assert.equals(
			JunitTestResultState.Passed,
			junit_parser.test_items['1'].current_state
		)
	end)

	it('test JUnit 4 failed result', function()
		local junit_parser = parser:new()
		junit_parser.lines = {
			'%TESTC  1 v2',
			'%TSTTREE1,shouldFail(junit4.TestAnnotation),false,1,false,-1,shouldFail(junit4.TestAnnotation),,',
			'%TESTS  1,shouldFail(junit4.TestAnnotation)',
			'%FAILED 1,shouldFail(junit4.TestAnnotation)',
			'%TRACES',
			'java.lang.AssertionError',
			'at org.junit.Assert.fail(Assert.java:87)',
			'at org.junit.Assert.assertTrue(Assert.java:42)',
			'at org.junit.Assert.assertTrue(Assert.java:53)',
			'at junit4.TestAnnotation.shouldFail(TestAnnotation.java:15)',
			'%TRACEE ',
			'%TESTE  1,shouldFail(junit4.TestAnnotation)',
			'%RUNTIME20;`;',
		}

		junit_parser:parse()
		assert.equals(
			JunitTestResultState.Failed,
			junit_parser.test_items['1'].current_state
		)
		assert.equals(
			table.concat({
				'java.lang.AssertionError',
				'at org.junit.Assert.fail(Assert.java:87)',
				'at org.junit.Assert.assertTrue(Assert.java:42)',
				'at org.junit.Assert.assertTrue(Assert.java:53)',
				'at junit4.TestAnnotation.shouldFail(TestAnnotation.java:15)',
			}, '\n'),
			junit_parser.test_items['1'].error.stack_trace
		)
	end)

	it('test Junit 5 test error', function()
		local junit_parser = parser:new()
		junit_parser.lines = {
			'%TESTC  1 v2',
			'%TSTTREE2,com.example.demo.DemoApplicationTests,true,1,false,1,\
			DemoApplicationTests,,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]',
			'%TSTTREE3,contextLoads3(com.example.demo.DemoApplicationTests),false,1,false,2,contextLoads3()\
			,,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]/[method:contextLoads3()]',
			'%TESTS  3,contextLoads3(com.example.demo.DemoApplicationTests)',

			'%ERROR  3,contextLoads3(com.example.demo.DemoApplicationTests)',
			'%TRACES',
			'java.lang.Error: Unresolved compilation problem:',
			'        Syntax error, insert ";" to complete Statement',
			'        at com.example.demo.DemoApplicationTests.contextLoads3(DemoApplicationTests.java:43)',
			'        at java.base/java.lang.reflect.Method.invoke(Method.java:568)',
			'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
			'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
			'%TRACEE',
			'%TESTE  3,contextLoads3(com.example.demo.DemoApplicationTests)',
			'%RUNTIME2262',
		}

		junit_parser:parse()
		assert.equals(
			JunitTestResultState.Failed,
			junit_parser.test_items['3'].current_state
		)
		assert.equals(
			table.concat({
				'java.lang.Error: Unresolved compilation problem:',
				'        Syntax error, insert ";" to complete Statement',
				'        at com.example.demo.DemoApplicationTests.contextLoads3(DemoApplicationTests.java:43)',
				'        at java.base/java.lang.reflect.Method.invoke(Method.java:568)',
				'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
				'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
			}, '\n'),
			junit_parser.test_items['3'].error.stack_trace
		)
	end)

	it('test Junit 5 failed test with expected message', function()
		local liens = {
			'%TESTC  1 v2',
			'%TSTTREE2,com.example.demo.DemoApplicationTests,true,1,false,1,DemoApplicationTests,,[engine:junit-jupiter]\
			/[class:com.example.demo.DemoApplicationTests]',
			'%TSTTREE3,contextLoads3(com.example.demo.DemoApplicationTests),false,1,false,2,contextLoads3(),,\
			[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]/[method:contextLoads3()]',
			'%TESTS  3,contextLoads3(com.example.demo.DemoApplicationTests)',
			'',
			'%FAILED 3,contextLoads3(com.example.demo.DemoApplicationTests)',
			'%EXPECTS',
			'4',
			'%EXPECTE',
			'%ACTUALS',
			'5',
			'%ACTUALE',
			'%TRACES',
			'org.opentest4j.AssertionFailedError: expected: <4> but was: <5>',
			'        at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:151)',
			'        at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:132)',
			'        at org.junit.jupiter.api.AssertEquals.failNotEqual(AssertEquals.java:197)',
			'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:150)',
			'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:145)',
			'        at org.junit.jupiter.api.Assertions.assertEquals(Assertions.java:531)',
			'        at com.example.demo.DemoApplicationTests.contextLoads3(DemoApplicationTests.java:43)',
			'        at java.base/java.lang.reflect.Method.invoke(Method.java:568)',
			'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
			'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
			'%TRACEE',
			'%TESTE  3,contextLoads3(com.example.demo.DemoApplicationTests)',
			'',
			'%RUNTIME2335',
		}

		local junit_parser = parser:new()
		junit_parser.lines = liens
		junit_parser:parse()

		assert.equals(
			JunitTestResultState.Failed,
			junit_parser.test_items['3'].current_state
		)
		assert.equals(
			table.concat({
				'org.opentest4j.AssertionFailedError: expected: <4> but was: <5>',
				'        at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:151)',
				'        at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:132)',
				'        at org.junit.jupiter.api.AssertEquals.failNotEqual(AssertEquals.java:197)',
				'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:150)',
				'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:145)',
				'        at org.junit.jupiter.api.Assertions.assertEquals(Assertions.java:531)',
				'        at com.example.demo.DemoApplicationTests.contextLoads3(DemoApplicationTests.java:43)',
				'        at java.base/java.lang.reflect.Method.invoke(Method.java:568)',
				'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
				'        at java.base/java.util.ArrayList.forEach(ArrayList.java:1511)',
			}, '\n'),
			junit_parser.test_items['3'].error.stack_trace
		)

		assert.equals('4', junit_parser.test_items['3'].error.expected)
		assert.equals('5', junit_parser.test_items['3'].error.actual)
	end)

	it('test Junit 5 parameterized test failed', function()
		local lines = {
			'%TESTC  0 v2',
			'%TSTTREE2,com.example.demo.DemoApplicationTests,true,1,false,1,DemoApplicationTests,,[engine:junit-jupiter]\
			/[class:com.example.demo.DemoApplicationTests]',
			'%TSTTREE3,contextLoads4(com.example.demo.DemoApplicationTests),true,0,false,2,contextLoads4(String),\
			java.lang.String,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]/\
			[test-template:contextLoads4(java.lang.String)]',
			'%TSTTREE4,contextLoads4(com.example.demo.DemoApplicationTests),false,1,true,3,[1] \
			inpt=Hello,java.lang.String,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests\
			/[test-template:contextLoads4(java.lang.String)]/[test-template-invocation:#1]',
			'%TESTS  4,contextLoads4(com.example.demo.DemoApplicationTests)',
			'',
			'%TESTE  4,contextLoads4(com.example.demo.DemoApplicationTests)',
			'',
			'%TSTTREE5,contextLoads4(com.example.demo.DemoApplicationTests),false,1,true,3,[2]\
			inpt=LOL,java.lang.String,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]\
			/[test-template:contextLoads4(java.lang.String)]/[test-template-invocation:#2]',
			'%TESTS  5,contextLoads4(com.example.demo.DemoApplicationTests)',
			'',
			'%FAILED 5,contextLoads4(com.example.demo.DemoApplicationTests)',
			'%EXPECTS',
			'Hello World',
			'%EXPECTE',
			'%ACTUALS',
			'Hello world',
			'%ACTUALE',
			'%TRACES ',
			'org.opentest4j.AssertionFailedError: expected: <Hello World> but was: <Hello world>',
			'        at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:151)',
			'        at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:132)',
			'%TRACEE ',
			'%TESTE  5,contextLoads4(com.example.demo.DemoApplicationTests)',
			'',
			'%RUNTIME2275',
		}

		local junit_parser = parser:new()
		junit_parser.lines = lines
		junit_parser:parse()
		assert.equals(
			JunitTestResultState.Failed,
			junit_parser.test_items['5'].current_state
		)
		assert.equals('Hello World', junit_parser.test_items['5'].error.expected)
		assert.equals('Hello world', junit_parser.test_items['5'].error.actual)
		assert.equals(
			table.concat({
				'org.opentest4j.AssertionFailedError: expected: <Hello World> but was: <Hello world>',
				'        at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:151)',
				'        at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:132)',
			}, '\n'),
			junit_parser.test_items['5'].error.stack_trace
		)
	end)

	it('test parameterized', function()
		local junit_parser = parser:new()
		local lines = {
			'%TESTC  0 v2',
			'%TSTTREE2,com.example.demo.DemoApplicationTests,true,1,false,1,DemoApplicationTests,,\
			[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]',
			'%TSTTREE3,contextLoads4(com.example.demo.DemoApplicationTests),true,0,false,2,contextLoads4(String)\
			,java.lang.String,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]/\
			[test-template:contextLoads4(java.lang.String)]',
			'%TSTTREE4,contextLoads4(com.example.demo.DemoApplicationTests),false,1,true,3,[1] inpt=Hello,java.lang\
			.String,[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]/\
			[test-template:contextLoads4(java.lang.String)]/[test-template-invocation:#1]',
			'%TESTS  4,contextLoads4(com.example.demo.DemoApplicationTests)',
			'%TESTE  4,contextLoads4(com.example.demo.DemoApplicationTests)',
			'%TSTTREE5,contextLoads4(com.example.demo.DemoApplicationTests),false,1,true,3,[2] inpt=LOL,java.lang.String,\
			[engine:junit-jupiter]/[class:com.example.demo.DemoApplicationTests]/[test-template:contextLoads4(java.lang.String)]\
			/[test-template-invocation:#2]',
			'%TESTS  5,contextLoads4(com.example.demo.DemoApplicationTests)',
			'%FAILED 5,contextLoads4(com.example.demo.DemoApplicationTests)',
			'%EXPECTS',
			'Hello',
			'%EXPECTE',
			'%ACTUALS',
			'LOL',
			'%ACTUALE',
			'%TRACES ',
			'org.opentest4j.AssertionFailedError: expected: <Hello> but was: <LOL>',
			'        at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:151)',
			'        at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:132)',
			'        at org.junit.jupiter.api.AssertEquals.failNotEqual(AssertEquals.java:197)',
			'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:182)',
			'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:177)',
			'%TRACEE ',
			'%TESTE  5,contextLoads4(com.example.demo.DemoApplicationTests)',
			'%RUNTIME2286',
		}
		junit_parser.lines = lines
		junit_parser:parse()

		-- check failed test
		assert.equals(
			JunitTestResultState.Failed,
			junit_parser.test_items['5'].current_state
		)
		assert.equals(
			'contextLoads4(com.example.demo.DemoApplicationTests)',
			junit_parser.test_items['5'].full_name
		)
		assert.equals('Hello', junit_parser.test_items['5'].error.expected)
		assert.equals('LOL', junit_parser.test_items['5'].error.actual)
		assert.equals(
			'[2] inpt=LOL',
			junit_parser.test_items['5'].dynamic_test_details
		)
		assert.equals(
			table.concat({
				'org.opentest4j.AssertionFailedError: expected: <Hello> but was: <LOL>',
				'        at org.junit.jupiter.api.AssertionFailureBuilder.build(AssertionFailureBuilder.java:151)',
				'        at org.junit.jupiter.api.AssertionFailureBuilder.buildAndThrow(AssertionFailureBuilder.java:132)',
				'        at org.junit.jupiter.api.AssertEquals.failNotEqual(AssertEquals.java:197)',
				'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:182)',
				'        at org.junit.jupiter.api.AssertEquals.assertEquals(AssertEquals.java:177)',
			}, '\n'),
			junit_parser.test_items['5'].error.stack_trace
		)

		-- check passed test
		assert.equals(
			JunitTestResultState.Passed,
			junit_parser.test_items['4'].current_state
		)
		assert.equals(
			'contextLoads4(com.example.demo.DemoApplicationTests)',
			junit_parser.test_items['4'].full_name
		)
		assert.equals(
			'[1] inpt=Hello',
			junit_parser.test_items['4'].dynamic_test_details
		)
	end)
end)
