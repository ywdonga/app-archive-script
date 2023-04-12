<template>
	<view class="empty">
		{{title}}
	</view>
</template>

<script>
	export default {
		data() {
			return {
				title: "没有任何应用"
			}
		}
	}
</script>

<style scoped>
	.empty {
		width: 100%;
		height: 100%;
		text-align: center;
	}
</style>