#pragma once
class HelloTri
{
public:
	struct SwapChainSupportDetails {
		VkSurfaceCapabilitiesKHR capabilities;
		std::vector<VkSurfaceFormatKHR> formats;
		std::vector<VkPresentModeKHR> presentModes;
	};
	
	static const int NUM_BUF = 3;	//3 hard coded
	static bool		sInitialized;
	static const VkFormat sSurfaceFormat = VK_FORMAT_R8G8B8A8_UNORM;

public:
	HelloTri();
	~HelloTri();
	void VulkanCreate();
	void VulkanRelease();
	void VulkanRender();


	VkExtent2D			m_swapChainExtent;
	VkInstance			m_VkInstance;
	VkPhysicalDevice	m_VkPhysicalDevice;
	VkDevice			m_VkDevice;
	VkQueue				m_VkQueue;
	VkSurfaceKHR		m_VkSurfaceKHR;
	VkSwapchainKHR		m_VkSwapchainKHR;
	VkImage				m_VkImage[NUM_BUF];
	VkImageView			m_VkImageView[NUM_BUF];	
	VkPipeline			m_VkPipeline;
	VkRenderPass		m_VkRenderPass;
	VkFramebuffer		m_VkFramebuffers[NUM_BUF];	// same # w m_VkImageView
	VkCommandPool		m_VkCommandPool;
	VkCommandBuffer		m_VkCommandBuffer[NUM_BUF];
	VkSemaphore			imageAvailableSemaphore;
	VkSemaphore			renderFinishedSemaphore;

	void PickPhysicalDevice();
	void createLogicalDevice();
	void createSurface();
	void createSwapChain();
	void createImageViews();
	void createGraphicsPipeline();
	void createRenderPass();
	void createFramebuffers();
	void createCommandPool();
	void createCommandBuffers();



	void createSemaphores();
};

