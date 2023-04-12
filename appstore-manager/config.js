

const ENV_VAL = 1; // 0:线上， 1: 测试

export default {
	
	baseUrl: function() {
		if (ENV_VAL === 0) {
			return ""
		}
		return "http://localhost:8080/";
	}
}