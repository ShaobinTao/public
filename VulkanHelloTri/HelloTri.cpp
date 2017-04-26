#include "stdafx.h"
#include "HelloTri.h"

bool	HelloTri::sInitialized = false;

static std::vector<char> readFile(const std::string& fileName) {
	std::ifstream file(fileName, std::ios::ate | std::ios::binary);

	if (!file.is_open()) {
		throw std::runtime_error("failed to open file!");
	}

	size_t fileSize = (size_t)file.tellg();
	std::vector<char> buffer(fileSize);
	file.seekg(0);
	file.read(buffer.data(), fileSize);

	file.close();
	return buffer;
}

static VKAPI_ATTR VkBool32 VKAPI_CALL debugCallback(
	VkDebugReportFlagsEXT flags,
	VkDebugReportObjectTypeEXT objType,
	uint64_t obj,
	size_t location,
	int32_t code,
	const char* layerPrefix,
	const char* msg,
	void* userData) {

	OutputDebugStringA(msg);


	assert(false);
	
	return VK_FALSE;
}

HelloTri::HelloTri()
{
}


HelloTri::~HelloTri()
{
}


void HelloTri::VulkanCreate()
{
	VkResult result = VK_SUCCESS;

	{// check extensions available
		uint32_t extensionCount = 0;
		result = vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, nullptr);
		assert(result == VK_SUCCESS);

		VkExtensionProperties	properties[3];
		result = vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, properties);
		assert(result == VK_SUCCESS);
		//-properties	0x003cf8a4 { {extensionName = 0x003cf8a4 "VK_KHR_surface" specVersion = 25 }, { extensionName = 0x003cf9a8 "VK_KHR_win32_surface" ... }, ...}	VkExtensionProperties[3]
		//	+ [0]{ extensionName = 0x003cf8a4 "VK_KHR_surface" specVersion = 25 }	VkExtensionProperties
		//	+ [1]{ extensionName = 0x003cf9a8 "VK_KHR_win32_surface" specVersion = 5 }	VkExtensionProperties
		//	+ [2]{ extensionName = 0x003cfaac "VK_EXT_debug_report" specVersion = 6 }	VkExtensionProperties

		uint32_t propertyCount = 0;
		result = vkEnumerateInstanceLayerProperties(&propertyCount, NULL);
		assert(result == VK_SUCCESS);

		VkLayerProperties	layerProperties[12];
		result = vkEnumerateInstanceLayerProperties(&propertyCount, layerProperties);
		assert(result == VK_SUCCESS);
		//-layerProperties	0x003ce030 { {layerName = 0x003ce030 "VK_LAYER_LUNARG_api_dump" specVersion = 4194350 implementationVersion = ...}, ...}	VkLayerProperties[12]
		//	+ [0]{ layerName = 0x003ce030 "VK_LAYER_LUNARG_api_dump" specVersion = 4194350 implementationVersion = 2 ... }	VkLayerProperties
		//	+ [1]{ layerName = 0x003ce238 "VK_LAYER_LUNARG_core_validation" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [2]{ layerName = 0x003ce440 "VK_LAYER_LUNARG_monitor" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [3]{ layerName = 0x003ce648 "VK_LAYER_LUNARG_object_tracker" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [4]{ layerName = 0x003ce850 "VK_LAYER_LUNARG_parameter_validation" specVersion = 4194350 implementationVersion = ... }	VkLayerProperties
		//	+ [5]{ layerName = 0x003cea58 "VK_LAYER_LUNARG_screenshot" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [6]{ layerName = 0x003cec60 "VK_LAYER_LUNARG_swapchain" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [7]{ layerName = 0x003cee68 "VK_LAYER_GOOGLE_threading" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [8]{ layerName = 0x003cf070 "VK_LAYER_GOOGLE_unique_objects" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [9]{ layerName = 0x003cf278 "VK_LAYER_LUNARG_vktrace" specVersion = 4194350 implementationVersion = 1 ... }	VkLayerProperties
		//	+ [10]{ layerName = 0x003cf480 "VK_LAYER_RENDERDOC_Capture" specVersion = 4194304 implementationVersion = 33 ... }	VkLayerProperties
		//	+ [11]{ layerName = 0x003cf688 "VK_LAYER_LUNARG_standard_validation" specVersion = 4194350 implementationVersion = ... }	VkLayerProperties
	}

// vkCreateInstance
	const char *extensions[] = {
		"VK_EXT_debug_report",
		"VK_KHR_surface",
		"VK_KHR_win32_surface"
	};

	const char *layers[] = {
		"VK_LAYER_LUNARG_api_dump",
		"VK_LAYER_LUNARG_standard_validation",
		"VK_LAYER_LUNARG_core_validation",
		"VK_LAYER_LUNARG_monitor",
		"VK_LAYER_LUNARG_object_tracker",
		"VK_LAYER_LUNARG_parameter_validation",
		"VK_LAYER_LUNARG_screenshot",
		"VK_LAYER_LUNARG_swapchain",
//		"VK_LAYER_LUNARG_vktrace",
		"VK_LAYER_RENDERDOC_Capture"
	};
	
	VkInstanceCreateInfo	ci = {};
	ci.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
	ci.enabledLayerCount = ARRAYSIZE(layers);
	ci.ppEnabledLayerNames = layers;
	ci.enabledExtensionCount = ARRAYSIZE(extensions);
	ci.ppEnabledExtensionNames = extensions;

	result = vkCreateInstance(&ci, NULL, &m_VkInstance);
	assert(result == VK_SUCCESS);

// vkCreateDebugReport (maybe incomplete, needs further checks)
	VkDebugReportCallbackCreateInfoEXT dbgCreateInfo = {};
	dbgCreateInfo.sType = VK_STRUCTURE_TYPE_DEBUG_REPORT_CALLBACK_CREATE_INFO_EXT;
	dbgCreateInfo.flags = VK_DEBUG_REPORT_ERROR_BIT_EXT | VK_DEBUG_REPORT_WARNING_BIT_EXT;
	dbgCreateInfo.pfnCallback = debugCallback;

	VkDebugReportCallbackEXT callback;

	auto func = (PFN_vkCreateDebugReportCallbackEXT)vkGetInstanceProcAddr(m_VkInstance, "vkCreateDebugReportCallbackEXT");

	result = func(m_VkInstance, &dbgCreateInfo, NULL, &callback);
	assert(result == VK_SUCCESS);

// SURFACE
	createSurface();

// physical device
	PickPhysicalDevice();

// logical device
	createLogicalDevice();

// swap chain
	createSwapChain();

// image view
	createImageViews();

// render pass
	createRenderPass();

// pipeline
	createGraphicsPipeline();

// fb
	createFramebuffers();

// command
	createCommandPool();
	createCommandBuffers();

// semaphore
	createSemaphores();

	sInitialized = true;
}


void HelloTri::VulkanRelease()
{
}

void HelloTri::PickPhysicalDevice()
{
	VkResult result = VK_SUCCESS;
	uint32_t count = 1;

	result = vkEnumeratePhysicalDevices(m_VkInstance, &count, NULL);
	assert(result == VK_SUCCESS);
	result = vkEnumeratePhysicalDevices(m_VkInstance, &count, &m_VkPhysicalDevice);
	assert(result == VK_SUCCESS);

	VkPhysicalDeviceProperties	prop;
	vkGetPhysicalDeviceProperties(
		m_VkPhysicalDevice,
		&prop
	);
	//-prop{ apiVersion = 4194304 driverVersion = 65539 vendorID = 32902 ... }	VkPhysicalDeviceProperties
	//	apiVersion	4194304	unsigned int
	//	driverVersion	65539	unsigned int
	//	vendorID	32902	unsigned int
	//	deviceID	6422	unsigned int
	//	deviceType	VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU(1)	VkPhysicalDeviceType
	//	+ deviceName	0x003cd630 "Intel(R) HD Graphics 520"	char[256]
	//	+ pipelineCacheUUID	0x003cd730 "rdoc170426083700...	unsigned char[16]
	//	+ limits{ maxImageDimension1D = 16384 maxImageDimension2D = 16384 maxImageDimension3D = 2048 ... }	VkPhysicalDeviceLimits
	//	+ sparseProperties{ residencyStandard2DBlockShape = 0 residencyStandard2DMultisampleBlockShape = 0 residencyStandard3DBlockShape = ... }	VkPhysicalDeviceSparseProperties
	assert(result == VK_SUCCESS);

	uint32_t queueFamilyPropertyCount = 0;
	vkGetPhysicalDeviceQueueFamilyProperties(m_VkPhysicalDevice,
		&queueFamilyPropertyCount,
		NULL);

	VkQueueFamilyProperties queueFamilyProperties;
	vkGetPhysicalDeviceQueueFamilyProperties(m_VkPhysicalDevice,
		&queueFamilyPropertyCount,
		&queueFamilyProperties);
	//-queueFamilyProperties{ queueFlags = 7 queueCount = 1 timestampValidBits = 36 ... }	VkQueueFamilyProperties
	//	queueFlags	7	unsigned int
	//	queueCount	1	unsigned int
	//	timestampValidBits	36	unsigned int
	//	+ minImageTransferGranularity{ width = 1 height = 1 depth = 1 }	VkExtent3D

	// vkGetPhysicalDeviceSurfaceSupportKHR must be called once so validation layer knows
	// we did the work
	VkBool32 supported = false;
	result = vkGetPhysicalDeviceSurfaceSupportKHR(
		m_VkPhysicalDevice,
		0,
		m_VkSurfaceKHR,
		&supported);

	{// device layers
		uint32_t deviceLayerCount = 0;
		result = vkEnumerateDeviceLayerProperties(
			m_VkPhysicalDevice,
			&deviceLayerCount,
			NULL);
		assert(result == VK_SUCCESS);

		VkLayerProperties	deviceLayer[5];
		result = vkEnumerateDeviceLayerProperties(
			m_VkPhysicalDevice,
			&deviceLayerCount,
			deviceLayer);
		assert(result == VK_SUCCESS);

		// check physical device extensions available
		uint32_t deviceExtensionCount = 0;
		result = vkEnumerateDeviceExtensionProperties(m_VkPhysicalDevice,
			NULL,
			&deviceExtensionCount,
			nullptr);
		VkExtensionProperties	properties[3];
		result = vkEnumerateDeviceExtensionProperties(m_VkPhysicalDevice,
			NULL,
			&deviceExtensionCount,
			properties);
		assert(result == VK_SUCCESS);
	}
}

void HelloTri::createLogicalDevice()
{
	const char *deviceExtensions[] = {
		"VK_KHR_swapchain",
		"VK_KHR_sampler_mirror_clamp_to_edge"
	};

	VkResult result = VK_SUCCESS;

	VkDeviceQueueCreateInfo	qci = {};
	float priority = 1.0;
	qci.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
	qci.queueFamilyIndex = 0;	// only 1 family exists
	qci.queueCount = 1;
	qci.pQueuePriorities = &priority;

	VkDeviceCreateInfo	device_info = {};
	device_info.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
	device_info.queueCreateInfoCount = 1;
	device_info.pQueueCreateInfos = &qci;
		device_info.enabledLayerCount = 0;			// deprecated and ignored
		device_info.ppEnabledLayerNames = NULL;		// deprecated and ignored
	device_info.enabledExtensionCount = ARRAYSIZE(deviceExtensions);
	device_info.ppEnabledExtensionNames = deviceExtensions;
	device_info.pEnabledFeatures = NULL;

	result = vkCreateDevice(m_VkPhysicalDevice,	
		&device_info, 
		NULL,	
		&m_VkDevice);
	assert(result == VK_SUCCESS);

	vkGetDeviceQueue(m_VkDevice,
		0,
		0,
		&m_VkQueue);


}


void HelloTri::createSurface()
{
	VkResult result = VK_SUCCESS;

	// win32 surface
	VkWin32SurfaceCreateInfoKHR	w32sci = {};
	w32sci.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
	w32sci.hinstance = ::GetModuleHandle(NULL);
	w32sci.hwnd = g_windowHandle;

	result = vkCreateWin32SurfaceKHR(
		m_VkInstance,
		&w32sci,
		NULL,
		&m_VkSurfaceKHR);
	assert(result == VK_SUCCESS);
}


void HelloTri::createSwapChain()
{
	VkResult result = VK_SUCCESS;

// SC caps
//	{
		VkSurfaceCapabilitiesKHR	caps;
		result = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(
			m_VkPhysicalDevice,
			m_VkSurfaceKHR,
			&caps);
		assert(result == VK_SUCCESS);
		//minImageCount	2	unsigned int
		//maxImageCount	0	unsigned int
		//+ currentExtent{ width = 4294967295 height = 4294967295 }	VkExtent2D
		//+ minImageExtent{ width = 1 height = 3435973836 }	VkExtent2D
		//+ maxImageExtent{ width = 16384 height = 16384 }	VkExtent2D
		//maxImageArrayLayers	2048	unsigned int
		//supportedTransforms	1	unsigned int
		//currentTransform	VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR(1)	VkSurfaceTransformFlagBitsKHR
		//supportedCompositeAlpha	3435973836	unsigned int
		//supportedUsageFlags	23	unsigned int
//	}

// SC surf formats
	{
		uint32_t	surfaceFormatCount = 0;
		result = vkGetPhysicalDeviceSurfaceFormatsKHR(
			m_VkPhysicalDevice,
			m_VkSurfaceKHR,
			&surfaceFormatCount,
			NULL);
		assert(result == VK_SUCCESS);

		VkSurfaceFormatKHR	surfaceFormats[4];
		result = vkGetPhysicalDeviceSurfaceFormatsKHR(
			m_VkPhysicalDevice,
			m_VkSurfaceKHR,
			&surfaceFormatCount,
			surfaceFormats);
		assert(result == VK_SUCCESS);
		//+ [0]{ format = VK_FORMAT_R8G8B8A8_UNORM(37) colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR(0) }	VkSurfaceFormatKHR
		//+ [1]{ format = VK_FORMAT_R8G8B8A8_SRGB(43)  colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR(0) }	VkSurfaceFormatKHR
		//+ [2]{ format = VK_FORMAT_B8G8R8A8_UNORM(44) colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR(0) }	VkSurfaceFormatKHR
		//+ [3]{ format = VK_FORMAT_B8G8R8A8_SRGB(50)  colorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR(0) }	VkSurfaceFormatKHR
	}

// present modes
	{
		uint32_t	presentModeCount = 0;
		result = vkGetPhysicalDeviceSurfacePresentModesKHR(
			m_VkPhysicalDevice,
			m_VkSurfaceKHR,
			&presentModeCount,
			NULL);
		assert(result == VK_SUCCESS);

		VkPresentModeKHR	presentModes[2];
		result = vkGetPhysicalDeviceSurfacePresentModesKHR(
			m_VkPhysicalDevice,
			m_VkSurfaceKHR,
			&presentModeCount,
			presentModes);
		assert(result == VK_SUCCESS);
		//[0]	VK_PRESENT_MODE_IMMEDIATE_KHR(0)	VkPresentModeKHR
		//[1]	VK_PRESENT_MODE_FIFO_KHR(2)	VkPresentModeKHR
	}

// Create SC
	VkSwapchainCreateInfoKHR	scci = {};

	m_swapChainExtent = caps.currentExtent;
	scci.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
	scci.surface = m_VkSurfaceKHR;
	scci.minImageCount = NUM_BUF;
	scci.imageFormat = sSurfaceFormat;
	scci.imageColorSpace = VK_COLOR_SPACE_SRGB_NONLINEAR_KHR;
	scci.imageExtent = m_swapChainExtent;
	scci.imageArrayLayers = 1;
	scci.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
	scci.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
	scci.queueFamilyIndexCount = 0;
	scci.pQueueFamilyIndices = NULL;
	scci.preTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR;
	scci.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
	scci.presentMode = VK_PRESENT_MODE_FIFO_KHR;
	scci.clipped = true;
	scci.oldSwapchain = VK_NULL_HANDLE;

	result = vkCreateSwapchainKHR(
		m_VkDevice,
		&scci,
		NULL,
		&m_VkSwapchainKHR);
	assert(result == VK_SUCCESS);

	uint32_t	swapchainImageCount = 0;
	result = vkGetSwapchainImagesKHR(
		m_VkDevice,
		m_VkSwapchainKHR,
		&swapchainImageCount,
		NULL);
	assert(result == VK_SUCCESS);

	result = vkGetSwapchainImagesKHR(
		m_VkDevice,
		m_VkSwapchainKHR,
		&swapchainImageCount,
		&m_VkImage[0]);
	assert(result == VK_SUCCESS);
}


void HelloTri::createImageViews()
{
	VkResult	result = VK_SUCCESS;

	VkImageViewCreateInfo	ici;
	ici.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
	ici.pNext = NULL;
	ici.flags = 0;
	ici.viewType = VK_IMAGE_VIEW_TYPE_2D;
	ici.format = sSurfaceFormat;
	ici.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
	ici.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
	ici.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
	ici.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
	ici.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
	ici.subresourceRange.baseMipLevel = 0;
	ici.subresourceRange.levelCount = 1;
	ici.subresourceRange.baseArrayLayer = 0;
	ici.subresourceRange.layerCount = 1;

	for (int i = 0; i < NUM_BUF; i++)	{
		ici.image = m_VkImage[i];

		result = vkCreateImageView(
			m_VkDevice,
			&ici,
			NULL,
			&m_VkImageView[i]);
		assert(result == VK_SUCCESS);
	}

}


void HelloTri::createGraphicsPipeline()
{
	VkResult	result = VK_SUCCESS;
	assert(result == VK_SUCCESS);

	auto vertShaderCode = readFile("shaders/vert.spv");
	auto fragShaderCode = readFile("shaders/frag.spv");

	VkShaderModuleCreateInfo	smci = {};
	smci.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO;
	smci.pNext = NULL;
	smci.flags = 0;

	// vert shader module
	VkShaderModule	vertShaderModule;
	smci.codeSize = vertShaderCode.size();
	std::vector<uint32_t> codeAligned1(vertShaderCode.size() / sizeof(uint32_t) + 1);
	memcpy(codeAligned1.data(), vertShaderCode.data(), vertShaderCode.size());
	smci.pCode = codeAligned1.data();
	result = vkCreateShaderModule(
		m_VkDevice,
		&smci,
		NULL,
		&vertShaderModule );
	assert(result == VK_SUCCESS);

	// frag shader module
	VkShaderModule	fragShaderModule;
	smci.codeSize = fragShaderCode.size();
	std::vector<uint32_t> codeAligned2(fragShaderCode.size() / sizeof(uint32_t) + 1);
	memcpy(codeAligned2.data(), fragShaderCode.data(), fragShaderCode.size());
	smci.pCode = codeAligned2.data();
	result = vkCreateShaderModule(
		m_VkDevice,
		&smci,
		NULL,
		&fragShaderModule);
	assert(result == VK_SUCCESS);

	// pipeline stage creation
	VkPipelineShaderStageCreateInfo	pssci_v = {};
	pssci_v.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
	pssci_v.stage = VK_SHADER_STAGE_VERTEX_BIT;
	pssci_v.module = vertShaderModule;
	pssci_v.pName = "main";

	VkPipelineShaderStageCreateInfo	pssci_f = {};
	pssci_f.sType = VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO;
	pssci_f.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
	pssci_f.module = fragShaderModule;
	pssci_f.pName = "main";

	VkPipelineShaderStageCreateInfo shaderStages[] = { pssci_v, pssci_f };

	// vkCreateGraphicsPipelines
	VkPipelineVertexInputStateCreateInfo	vici = {};
	vici.sType = VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
	vici.pNext = NULL;
	vici.flags = 0;
	vici.vertexBindingDescriptionCount = 0;
	vici.pVertexBindingDescriptions = NULL;
	vici.vertexAttributeDescriptionCount = 0;
	vici.pVertexAttributeDescriptions = NULL;

	VkPipelineInputAssemblyStateCreateInfo	InputAssemblyState = {};
	InputAssemblyState.sType = VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
	InputAssemblyState.pNext = NULL;
	InputAssemblyState.flags = 0;
	InputAssemblyState.topology = VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
	InputAssemblyState.primitiveRestartEnable = VK_FALSE;

	VkViewport	viewport = {};
	VkRect2D scissor = {};
	scissor.offset = { 0, 0 };
	scissor.extent = m_swapChainExtent;
	VkPipelineViewportStateCreateInfo         ViewportState = {};
	viewport.x = 0;
	viewport.y = 0;
	viewport.width = m_swapChainExtent.width;
	viewport.height = m_swapChainExtent.height;
	viewport.minDepth = 0.0f;
	viewport.maxDepth = 1.0f;
	ViewportState.sType = VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO;
	ViewportState.pNext = NULL;
	ViewportState.flags = 0;
	ViewportState.viewportCount = 1;
	ViewportState.pViewports = &viewport;
	ViewportState.scissorCount = 1;
	ViewportState.pScissors = &scissor;

	VkPipelineRasterizationStateCreateInfo    RasterizationState = {};
	RasterizationState.sType = VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
	RasterizationState.pNext = NULL;
	RasterizationState.flags = 0;
	RasterizationState.depthClampEnable = VK_FALSE;
	RasterizationState.rasterizerDiscardEnable = VK_FALSE;
	RasterizationState.polygonMode = VK_POLYGON_MODE_FILL;
	RasterizationState.cullMode = VK_CULL_MODE_BACK_BIT;
	RasterizationState.frontFace = VK_FRONT_FACE_CLOCKWISE;
	RasterizationState.depthBiasEnable = VK_FALSE;
	RasterizationState.depthBiasConstantFactor = 0.0f;
	RasterizationState.depthBiasClamp = 0.0f;
	RasterizationState.depthBiasSlopeFactor = 0.0f;
	RasterizationState.lineWidth = 1.0f;

	VkPipelineMultisampleStateCreateInfo      MultisampleState = {};
	MultisampleState.sType = VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
	MultisampleState.pNext = NULL;
	MultisampleState.flags = 0;
	MultisampleState.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
	MultisampleState.sampleShadingEnable = VK_FALSE;
	MultisampleState.minSampleShading = 1.0f;
	MultisampleState.pSampleMask = NULL;
	MultisampleState.alphaToCoverageEnable = VK_FALSE;
	MultisampleState.alphaToOneEnable = VK_FALSE;

	VkPipelineColorBlendStateCreateInfo     ColorBlendState = {};
	VkPipelineColorBlendAttachmentState		attachments = {};
	attachments.blendEnable = VK_FALSE;
	attachments.srcColorBlendFactor = VK_BLEND_FACTOR_ONE;
	attachments.dstColorBlendFactor = VK_BLEND_FACTOR_ZERO;
	attachments.colorBlendOp = VK_BLEND_OP_ADD;
	attachments.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
	attachments.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO;
	attachments.alphaBlendOp = VK_BLEND_OP_ADD;
	attachments.colorWriteMask = VK_COLOR_COMPONENT_R_BIT | VK_COLOR_COMPONENT_G_BIT | VK_COLOR_COMPONENT_B_BIT | VK_COLOR_COMPONENT_A_BIT;
	ColorBlendState.sType = VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
	ColorBlendState.pNext = NULL;
	ColorBlendState.flags = 0;
	ColorBlendState.logicOpEnable = VK_FALSE;
	ColorBlendState.logicOp = VK_LOGIC_OP_COPY;
	ColorBlendState.attachmentCount = 1;
	ColorBlendState.pAttachments = &attachments;
	ColorBlendState.blendConstants[0] = 0.0f;
	ColorBlendState.blendConstants[1] = 0.0f;
	ColorBlendState.blendConstants[2] = 0.0f;
	ColorBlendState.blendConstants[3] = 0.0f;

	VkPipelineLayout			layout = {};
	VkPipelineLayoutCreateInfo	pipelineLayoutInfo = {};
	pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
	pipelineLayoutInfo.setLayoutCount = 0;
	pipelineLayoutInfo.pSetLayouts = nullptr;
	pipelineLayoutInfo.pushConstantRangeCount = 0;
	pipelineLayoutInfo.pPushConstantRanges = 0;
	result = vkCreatePipelineLayout(
		m_VkDevice,
		&pipelineLayoutInfo,
		NULL,
		&layout);
	assert(result == VK_SUCCESS);

	VkGraphicsPipelineCreateInfo	gpci = {};
	gpci.sType = VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO;
	gpci.pNext = NULL;
	gpci.flags = VK_PIPELINE_CREATE_DISABLE_OPTIMIZATION_BIT;
	gpci.stageCount = 2;
	gpci.pStages = shaderStages;
	gpci.pVertexInputState = &vici;
	gpci.pInputAssemblyState = &InputAssemblyState;
	gpci.pViewportState = &ViewportState;
	gpci.pRasterizationState = &RasterizationState;
	gpci.pMultisampleState = &MultisampleState;
	gpci.pDepthStencilState = nullptr;
	gpci.pColorBlendState = &ColorBlendState;
	gpci.pDynamicState = nullptr;
	gpci.layout = layout;
	gpci.renderPass = m_VkRenderPass;
	gpci.subpass = 0;
	gpci.basePipelineHandle = VK_NULL_HANDLE;
	gpci.basePipelineIndex = -1;

	result = vkCreateGraphicsPipelines(
		m_VkDevice, 
		VK_NULL_HANDLE,
		1,
		&gpci,
		NULL,
		&m_VkPipeline);
	assert(result == VK_SUCCESS);



	vkDestroyShaderModule(
		m_VkDevice,
		vertShaderModule,
		NULL);
	vkDestroyShaderModule(
		m_VkDevice,
		fragShaderModule,
		NULL);
}


void HelloTri::createRenderPass()
{
	VkResult	result = VK_SUCCESS;

	VkAttachmentDescription	attachments = {};
	attachments.flags = 0;
	attachments.format = sSurfaceFormat;
	attachments.samples = VK_SAMPLE_COUNT_1_BIT;
	attachments.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
	attachments.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
	attachments.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
	attachments.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
	attachments.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
	attachments.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

	VkAttachmentReference	colorAttachments = {};
	colorAttachments.attachment = 0;
	colorAttachments.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

	VkSubpassDescription	subpasses = {};
	subpasses.flags = 0;
	subpasses.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
	subpasses.inputAttachmentCount = 0;
	subpasses.pInputAttachments = nullptr;
	subpasses.colorAttachmentCount = 1;
	subpasses.pColorAttachments = &colorAttachments;
	subpasses.pResolveAttachments = 0;
	subpasses.pDepthStencilAttachment = nullptr;
	subpasses.preserveAttachmentCount = 0;
	subpasses.pPreserveAttachments = nullptr;

	VkRenderPassCreateInfo	createInfo = {};
	VkSubpassDependency dependency = {};
	dependency.srcSubpass = VK_SUBPASS_EXTERNAL;
	dependency.dstSubpass = 0;
	dependency.srcStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
	dependency.srcAccessMask = 0;
	dependency.dstStageMask = VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT;
	dependency.dstAccessMask = VK_ACCESS_COLOR_ATTACHMENT_READ_BIT | VK_ACCESS_COLOR_ATTACHMENT_WRITE_BIT;

	createInfo.sType = VK_STRUCTURE_TYPE_RENDER_PASS_CREATE_INFO;
	createInfo.pNext = NULL;
	createInfo.flags = 0;
	createInfo.attachmentCount = 1;
	createInfo.pAttachments = &attachments;
	createInfo.subpassCount = 1;
	createInfo.pSubpasses = &subpasses;
	createInfo.dependencyCount = 1;
	createInfo.pDependencies = &dependency;

	result = vkCreateRenderPass(
		m_VkDevice,
		&createInfo,
		NULL,
		&m_VkRenderPass);
	assert(result == VK_SUCCESS);


}


void HelloTri::createFramebuffers()
{
	VkResult	result = VK_SUCCESS;
	VkFramebufferCreateInfo framebufferInfo = {};
	framebufferInfo.sType = VK_STRUCTURE_TYPE_FRAMEBUFFER_CREATE_INFO;
	framebufferInfo.renderPass = m_VkRenderPass;
	framebufferInfo.attachmentCount = 1;
	framebufferInfo.width = m_swapChainExtent.width;
	framebufferInfo.height = m_swapChainExtent.height;
	framebufferInfo.layers = 1;

	for (size_t i = 0; i < 3; i++) {
		framebufferInfo.pAttachments = &m_VkImageView[i];

		result = vkCreateFramebuffer(m_VkDevice, &framebufferInfo, nullptr, &m_VkFramebuffers[i]);
		assert(result == VK_SUCCESS);
	}


}

void HelloTri::createCommandPool()
{
	VkResult	result = VK_SUCCESS;
	VkCommandPoolCreateInfo	createInfo = {};
	createInfo.sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO;
	createInfo.queueFamilyIndex = 0;

	result = vkCreateCommandPool(
		m_VkDevice,
		&createInfo,
		NULL,
		&m_VkCommandPool);
	assert(result == VK_SUCCESS);

}


void HelloTri::createCommandBuffers()
{
	VkResult	result = VK_SUCCESS;
	VkCommandBufferAllocateInfo		allocateInfo = {};
	allocateInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
	allocateInfo.commandPool = m_VkCommandPool;
	allocateInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
	allocateInfo.commandBufferCount = 3;

	result = vkAllocateCommandBuffers(
		m_VkDevice,
		&allocateInfo,
		m_VkCommandBuffer);
	assert(result == VK_SUCCESS);

	VkCommandBufferBeginInfo	beginInfo = {};
	beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
	beginInfo.flags = VK_COMMAND_BUFFER_USAGE_SIMULTANEOUS_USE_BIT;

	VkRenderPassBeginInfo	renderPassBegin = {};
	renderPassBegin.sType = VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO;

	for (int i = 0; i < 3; i++) {
		result = vkBeginCommandBuffer( m_VkCommandBuffer[i], &beginInfo);			assert(result == VK_SUCCESS);
		{
			renderPassBegin.renderPass = m_VkRenderPass;
			renderPassBegin.framebuffer = m_VkFramebuffers[i];
			renderPassBegin.renderArea.offset = { 0, 0 };
			renderPassBegin.renderArea.extent = m_swapChainExtent;
			VkClearValue clearColor = { 0.0f, 0.0f, 0.0f, 1.0f };
			renderPassBegin.clearValueCount = 1;
			renderPassBegin.pClearValues = &clearColor;

			vkCmdBeginRenderPass(m_VkCommandBuffer[i], &renderPassBegin,VK_SUBPASS_CONTENTS_INLINE);
			{
				vkCmdBindPipeline(m_VkCommandBuffer[i], VK_PIPELINE_BIND_POINT_GRAPHICS, m_VkPipeline);
				{
					vkCmdDraw( m_VkCommandBuffer[i], 3, 1, 0, 0);
				}
			}
			vkCmdEndRenderPass(m_VkCommandBuffer[i]);
		}
		vkEndCommandBuffer(m_VkCommandBuffer[i]);
	}
}

void HelloTri::createSemaphores()
{
	VkResult	result = VK_SUCCESS;
	VkSemaphoreCreateInfo	createInfo = {};
	createInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_CREATE_INFO;

	result = vkCreateSemaphore(
		m_VkDevice,
		&createInfo,
		NULL,
		&imageAvailableSemaphore);
	assert(result == VK_SUCCESS);

	result = vkCreateSemaphore(
		m_VkDevice,
		&createInfo,
		NULL,
		&renderFinishedSemaphore);
	assert(result == VK_SUCCESS);
}

void HelloTri::VulkanRender()
{
	if (sInitialized == false) {
		return;
	}

	VkResult	result = VK_SUCCESS;

	uint32_t imageIndex;
	result = vkAcquireNextImageKHR(
		m_VkDevice,
		m_VkSwapchainKHR,
		UINT64_MAX,
		imageAvailableSemaphore,
		VK_NULL_HANDLE,
		&imageIndex);
	assert(result == VK_SUCCESS);

	VkSubmitInfo	submits = {};
	VkSemaphore waitSemaphores[] = { imageAvailableSemaphore };
	VkPipelineStageFlags waitStages[] = { VK_PIPELINE_STAGE_COLOR_ATTACHMENT_OUTPUT_BIT };
	VkSemaphore signalSemaphores[] = { renderFinishedSemaphore };

	submits.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
	submits.waitSemaphoreCount = 1;
	submits.pWaitSemaphores = waitSemaphores;
	submits.pWaitDstStageMask = waitStages;
	submits.commandBufferCount = 1;
	submits.pCommandBuffers = &m_VkCommandBuffer[imageIndex];
	submits.signalSemaphoreCount = 1;
	submits.pSignalSemaphores = signalSemaphores;

	result = vkQueueSubmit(m_VkQueue, 1, &submits, VK_NULL_HANDLE);
	assert(result == VK_SUCCESS);

	VkSwapchainKHR swapChains[] = { m_VkSwapchainKHR };

	VkPresentInfoKHR	presentInfo = {};
	presentInfo.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR;
	presentInfo.waitSemaphoreCount = 1;
	presentInfo.pWaitSemaphores = signalSemaphores;
	presentInfo.swapchainCount = 1;
	presentInfo.pSwapchains = swapChains;
	presentInfo.pImageIndices = &imageIndex;
	presentInfo.pResults = nullptr;

	result = vkQueuePresentKHR(
		m_VkQueue,
		&presentInfo);
	assert(result == VK_SUCCESS);

}



