/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2023 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"
#include "adc.h"
#include "dma.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */
ALIGN_32BYTES (uint16_t adc1_data[FFT_LENGTH]) 	__attribute__((section(".ARM.__at_0x30000000")));
ALIGN_32BYTES (uint16_t adc2_data[FFT_LENGTH]) 	__attribute__((section(".ARM.__at_0x30020000")));
ALIGN_32BYTES (uint16_t adc3_data[FFT_LENGTH]) 	__attribute__((section(".ARM.__at_0x30040000")));
__IO uint8_t Adc1_ConvEnd = 0;//表示adc1采集完成
__IO uint8_t Adc2_ConvEnd = 0;//表示adc2采集完成
__IO uint8_t Adc3_ConvEnd = 0;//表示adc3采集完成

uint8_t	K1_state,K2_state=0;
u8 flag=0;
float	Vpp_adc1,Vpp_adc2,Vpp_adc3;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
void PeriphCommonClock_Config(void);
static void MPU_Initialize(void);
static void MPU_Config(void);
/* USER CODE BEGIN PFP */

void adc1_init(void);
void adc2_init(void);
void adc3_init(void);
void Find_Vpp(uint8_t	ADCX);
void test(void);
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* Enable I-Cache---------------------------------------------------------*/
  SCB_EnableICache();

  /* Enable D-Cache---------------------------------------------------------*/
  SCB_EnableDCache();

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* MPU Configuration--------------------------------------------------------*/
  MPU_Config();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

/* Configure the peripherals common clocks */
  PeriphCommonClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_USART2_UART_Init();
  MX_ADC1_Init();
  MX_USART1_UART_Init();
  MX_ADC2_Init();
  MX_ADC3_Init();
  MX_TIM7_Init();
  MX_TIM1_Init();
  MX_TIM15_Init();
  MX_TIM8_Init();
  /* USER CODE BEGIN 2 */
	
	printf("start\n"); 
	Uart_printf(&huart2,"%d\r\n",1000); 
	float	Vs,Vi;
	float	Vo,VoL;
	float	R_in,R_out;		//输入输出电阻
	float	Av;						//电压增益
	float Vdc,Vac;
HAL_GPIO_WritePin(GPIOB,GPIO_PIN_0,0);
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
		
		//测量输入输出电阻，电压增益	1kHz
		if(K1_state == 1&&flag==0)
		{
			K1_state=0;
			printf("K1\n");
			Uart_printf(&huart2,"%d\r\n",10);
			Uart_printf(&huart2,"%d\r\n",10);//10对应1k
			
			//！！电压是真实值！！有放大需修正
			//测量输入电阻
			
			adc1_init();
			Find_Vpp(1);
		
			adc2_init();
			Find_Vpp(2);

			Vs =Vpp_adc1;
			Vi =Vpp_adc2;
			R_in = Vi/(Vs-Vi)*2000;		//Ri取2kΩ时,2k实测1950
			printf("R_in = %f\n",R_in);
			
//			测量输出电阻	不接负载为常态，K1断开
				HAL_GPIO_WritePin(GPIOB,0,0);
				adc3_init();
				Find_Vpp(3);
				Vo = Vpp_adc3;
//			//模拟开关控制，接入负载，K1闭合
				HAL_GPIO_WritePin(GPIOB,0,1);
				adc3_init();
				Find_Vpp(3);
				VoL = Vpp_adc3;
				R_out = (Vo/VoL-1)*10000;
				printf("R_out=%f\n",R_out);
//			//测量电压增益
//			Av = Vo/Vi;
			
		}
		
		//测量幅频响应		截止频率160k左右
		if(K2_state == 1&&flag==0)
		{
			K2_state=0;
			printf("K2\n");
			
			printf("1k\n");
			Uart_printf(&huart2,"%d\r\n",10);
			Uart_printf(&huart2,"%d\r\n",10);
			
			//采样求增益
			
			printf("10k\n");
			Uart_printf(&huart2,"%d\r\n",100);
			Uart_printf(&huart2,"%d\r\n",100);
			
			//采样求增益
			
			printf("30k\n");
			Uart_printf(&huart2,"%d\r\n",300);
			Uart_printf(&huart2,"%d\r\n",300);
			
			//采样求增益
			
		}
		//故障检测
		if(flag==1)
		{
			test();
		}
  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Supply configuration update enable
  */
  HAL_PWREx_ConfigSupply(PWR_LDO_SUPPLY);

  /** Configure the main internal regulator output voltage
  */
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  while(!__HAL_PWR_GET_FLAG(PWR_FLAG_VOSRDY)) {}

  __HAL_RCC_SYSCFG_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE0);

  while(!__HAL_PWR_GET_FLAG(PWR_FLAG_VOSRDY)) {}

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
  RCC_OscInitStruct.HSEState = RCC_HSE_ON;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
  RCC_OscInitStruct.PLL.PLLM = 5;
  RCC_OscInitStruct.PLL.PLLN = 192;
  RCC_OscInitStruct.PLL.PLLP = 2;
  RCC_OscInitStruct.PLL.PLLQ = 2;
  RCC_OscInitStruct.PLL.PLLR = 2;
  RCC_OscInitStruct.PLL.PLLRGE = RCC_PLL1VCIRANGE_2;
  RCC_OscInitStruct.PLL.PLLVCOSEL = RCC_PLL1VCOWIDE;
  RCC_OscInitStruct.PLL.PLLFRACN = 0;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2
                              |RCC_CLOCKTYPE_D3PCLK1|RCC_CLOCKTYPE_D1PCLK1;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.SYSCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB3CLKDivider = RCC_APB3_DIV2;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_APB1_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_APB2_DIV2;
  RCC_ClkInitStruct.APB4CLKDivider = RCC_APB4_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_4) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief Peripherals Common Clock Configuration
  * @retval None
  */
void PeriphCommonClock_Config(void)
{
  RCC_PeriphCLKInitTypeDef PeriphClkInitStruct = {0};

  /** Initializes the peripherals clock
  */
  PeriphClkInitStruct.PeriphClockSelection = RCC_PERIPHCLK_ADC;
  PeriphClkInitStruct.PLL2.PLL2M = 25;
  PeriphClkInitStruct.PLL2.PLL2N = 360;
  PeriphClkInitStruct.PLL2.PLL2P = 5;
  PeriphClkInitStruct.PLL2.PLL2Q = 2;
  PeriphClkInitStruct.PLL2.PLL2R = 2;
  PeriphClkInitStruct.PLL2.PLL2RGE = RCC_PLL2VCIRANGE_0;
  PeriphClkInitStruct.PLL2.PLL2VCOSEL = RCC_PLL2VCOWIDE;
  PeriphClkInitStruct.PLL2.PLL2FRACN = 0;
  PeriphClkInitStruct.AdcClockSelection = RCC_ADCCLKSOURCE_PLL2;
  if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
}

/* USER CODE BEGIN 4 */
	//求采样数据峰峰值
void Find_Vpp(uint8_t	ADCX)
{
	float vi_max,vi_min;
	float voltage = 0;
	
	if(ADCX==1)
	{
			vi_max = adc1_data[30]*3.3/65535;
			vi_min = adc1_data[30]*3.3/65535;
			for (u16 temp = 10 ;temp < FFT_LENGTH-10 ;temp++)
			{
				voltage = adc1_data[temp]*3.3/65535;
				if(voltage>vi_max)
				{
					vi_max = voltage;
				}
				if(voltage<vi_min)
				{
					vi_min = voltage;
				}
			}
		Vpp_adc1 = vi_max - vi_min;
		printf("vi_max = %f\n",vi_max);
		printf("vi_min = %f\n",vi_min);
		printf("Vpp_adc1 = %f\n",Vpp_adc1);
	}
	else if(ADCX==2)
	{
			vi_max = adc2_data[30]*3.3/65535;
			vi_min = adc2_data[30]*3.3/65535;
			for (u16 temp = 10 ;temp < FFT_LENGTH-10 ;temp++)
			{
				voltage = adc2_data[temp]*3.3/65535;
				if(voltage>vi_max)
				{
					vi_max = voltage;
				}
				if(voltage<vi_min)
				{
					vi_min = voltage;
				}
			}
		Vpp_adc2 = vi_max - vi_min;
		printf("vi_max = %f\n",vi_max);
		printf("vi_min = %f\n",vi_min);
		printf("Vpp_adc2 = %f\n",Vpp_adc2);
	}
	else if(ADCX==3)
	{
			vi_max = adc3_data[30]*3.3/65535;
			vi_min = adc3_data[30]*3.3/65535;
			for (u16 temp = 10 ;temp < FFT_LENGTH-10 ;temp++)
			{
				voltage = adc3_data[temp]*3.3/65535;
				if(voltage>vi_max)
				{
					vi_max = voltage;
				}
				if(voltage<vi_min)
				{
					vi_min = voltage;
				}
			}
		Vpp_adc3 = vi_max - vi_min;
		printf("vi_max = %f\n",vi_max);
		printf("vi_min = %f\n",vi_min);
		printf("Vpp_adc3 = %f\n",Vpp_adc3);
	}
}
	//IO中断
void HAL_GPIO_EXTI_Callback(uint16_t GPIO_Pin)
{
	if(GPIO_Pin == K1_Pin)
	{
		K1_state = 1;
	}
	if(GPIO_Pin == K2_Pin)
	{
		K2_state = 1;
	}
}
	//ADC
void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc)
{
   if(hadc->Instance == ADC1) 
	{
      //SCB_InvalidateDCache_by_Addr((uint32_t *) &adc1_data[0], ADC1_BUFFER_SIZE);
		Adc1_ConvEnd = 1;
  }
   if(hadc->Instance == ADC2) 
	{
      //SCB_InvalidateDCache_by_Addr((uint32_t *) &adc1_data[0], ADC1_BUFFER_SIZE);
		Adc2_ConvEnd = 1;
  }
   if(hadc->Instance == ADC3) 
	{
      //SCB_InvalidateDCache_by_Addr((uint32_t *) &adc1_data[0], ADC1_BUFFER_SIZE);
		Adc3_ConvEnd = 1;
  }
}
	//adc校准及启动采栿
void adc1_init(void)
{
	printf("start_adc1\n");
	MX_ADC1_Init();	//初始化调用放这里, 确保在MX_DMA_Init()初始化后靿  	
//	TIM15->PSC =5-1;
	HAL_Delay(100);	//有地方说这里可以等等电压稳定后再校准
	if (HAL_ADCEx_Calibration_Start(&hadc1, ADC_CALIB_OFFSET, ADC_SINGLE_ENDED) != HAL_OK)
	{
			printf("hadc1 error with HAL_ADCEx_Calibration_Start\r\n");
			Error_Handler();
	}

	if (HAL_ADC_Start_DMA(&hadc1, (uint32_t *)adc1_data, FFT_LENGTH) != HAL_OK)
	{
			printf("hadc1 error with HAL_ADC_Start_DMA\r\n");
			Error_Handler();
	}

	HAL_TIM_Base_Start(&htim15);
	while (!Adc1_ConvEnd);
	Adc1_ConvEnd = 0;
	HAL_ADC_DeInit(&hadc1);			//逆初始化
	HAL_TIM_Base_Stop(&htim15);
}

void adc2_init(void)
{
	printf("start_adc2\n");
	MX_ADC2_Init();	//初始化调用放这里, 确保在MX_DMA_Init()初始化后靿  	
//	TIM4->PSC =5-1;
	HAL_Delay(100);	//有地方说这里可以等等电压稳定后再校准
	if (HAL_ADCEx_Calibration_Start(&hadc2, ADC_CALIB_OFFSET, ADC_SINGLE_ENDED) != HAL_OK)
	{
			printf("hadc2 error with HAL_ADCEx_Calibration_Start\r\n");
			Error_Handler();
	}

	if (HAL_ADC_Start_DMA(&hadc2, (uint32_t *)adc2_data, FFT_LENGTH) != HAL_OK)
	{
			printf("hadc2 error with HAL_ADC_Start_DMA\r\n");
			Error_Handler();
	}

	HAL_TIM_Base_Start(&htim8);
	while (!Adc2_ConvEnd);
	Adc2_ConvEnd = 0;
	HAL_ADC_DeInit(&hadc2);			//逆初始化
	HAL_TIM_Base_Stop(&htim8);
}

void adc3_init(void)
{
	printf("start_adc3\n");
	MX_ADC3_Init();	//初始化调用放这里, 确保在MX_DMA_Init()初始化后靿  	
//	TIM1->PSC =80-1;
	HAL_Delay(100);	//有地方说这里可以等等电压稳定后再校准
	if (HAL_ADCEx_Calibration_Start(&hadc3, ADC_CALIB_OFFSET, ADC_SINGLE_ENDED) != HAL_OK)
	{
			printf("hadc3 error with HAL_ADCEx_Calibration_Start\r\n");
			Error_Handler();
	}

	if (HAL_ADC_Start_DMA(&hadc3, (uint32_t *)adc3_data, FFT_LENGTH) != HAL_OK)
	{
			printf("hadc3 error with HAL_ADC_Start_DMA\r\n");
			Error_Handler();
	}

	HAL_TIM_Base_Start(&htim1);
	while (!Adc3_ConvEnd);
	Adc3_ConvEnd = 0;
	HAL_ADC_DeInit(&hadc3);			//逆初始化
	HAL_TIM_Base_Stop(&htim1);
}

void test()
{
	//根据Vi（adc2）、DC、AC判断
	//正常
	//R1断路
	//R2断路
	//R3断路
	//R4断路
	//R1短路
	//R2短路
	//R3短路
	//R4短路
	//C1断路
	//C2断路
	//C3断路
	//C1两倍
	//C2两倍
	//C3两倍
}
/* USER CODE END 4 */

/* MPU Configuration */

void MPU_Config(void)
{
  MPU_Region_InitTypeDef MPU_InitStruct = {0};

  /* Disables the MPU */
  HAL_MPU_Disable();

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Enable = MPU_REGION_ENABLE;
  MPU_InitStruct.Number = MPU_REGION_NUMBER0;
  MPU_InitStruct.BaseAddress = 0x24000000;
  MPU_InitStruct.Size = MPU_REGION_SIZE_512KB;
  MPU_InitStruct.SubRegionDisable = 0x0;
  MPU_InitStruct.TypeExtField = MPU_TEX_LEVEL1;
  MPU_InitStruct.AccessPermission = MPU_REGION_FULL_ACCESS;
  MPU_InitStruct.DisableExec = MPU_INSTRUCTION_ACCESS_ENABLE;
  MPU_InitStruct.IsShareable = MPU_ACCESS_NOT_SHAREABLE;
  MPU_InitStruct.IsCacheable = MPU_ACCESS_CACHEABLE;
  MPU_InitStruct.IsBufferable = MPU_ACCESS_BUFFERABLE;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Number = MPU_REGION_NUMBER1;
  MPU_InitStruct.BaseAddress = 0x30000000;
  MPU_InitStruct.Size = MPU_REGION_SIZE_128KB;
  MPU_InitStruct.IsCacheable = MPU_ACCESS_NOT_CACHEABLE;
  MPU_InitStruct.IsBufferable = MPU_ACCESS_NOT_BUFFERABLE;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Number = MPU_REGION_NUMBER2;
  MPU_InitStruct.BaseAddress = 0x30020000;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Number = MPU_REGION_NUMBER3;
  MPU_InitStruct.BaseAddress = 0x30040000;
  MPU_InitStruct.Size = MPU_REGION_SIZE_32KB;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);

  /** Initializes and configures the Region and the memory to be protected
  */
  MPU_InitStruct.Number = MPU_REGION_NUMBER4;
  MPU_InitStruct.BaseAddress = 0x38000000;
  MPU_InitStruct.Size = MPU_REGION_SIZE_64KB;

  HAL_MPU_ConfigRegion(&MPU_InitStruct);
  /* Enables the MPU */
  HAL_MPU_Enable(MPU_PRIVILEGED_DEFAULT);

}

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
