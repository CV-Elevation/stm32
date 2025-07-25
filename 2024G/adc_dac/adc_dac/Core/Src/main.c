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
#include "dac.h"
#include "dma.h"
#include "memorymap.h"
#include "tim.h"
#include "usart.h"
#include "gpio.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */
ALIGN_32BYTES (uint16_t adc1_data[FFT_LENGTH]) 	__attribute__((section(".ARM.__at_0x30000000")));
__IO uint8_t AdcConvEnd = 0;//表示adc采集完成

ALIGN_32BYTES (uint16_t Dat[100]) 	__attribute__((section(".ARM.__at_0x38000000")));

float	vi_max,vi_min;
float	delta_v;
int8_t	sound_flag = 0;
uint8_t	adc_times=0;

void adc_init(void)
{
	printf("start_adc\n");
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
	while (!AdcConvEnd);
	AdcConvEnd = 0;
	HAL_ADC_DeInit(&hadc1);			//逆初始化
	HAL_TIM_Base_Stop(&htim15);
}

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
void SineWave()
{
    uint16_t i;
    for( i=0;i<100;i++)
    {
			//正弦波frequency = htim时钟的频率/100
  		Dat[i]=(uint16_t)((int16_t)(2048*sin(i*2*3.1415926/100))+2048);	//“200”点=period
		//稳定电压
//			Dat[i] = 4095;
    }
	
//	//方波
//	Dat[0] = 0;
//	Dat[1] = 4095;
}

void Find_Vpp(void);

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/

/* USER CODE BEGIN PV */

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MPU_Config(void);
/* USER CODE BEGIN PFP */

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

  /* MPU Configuration--------------------------------------------------------*/
  MPU_Config();

  /* Enable the CPU Cache */

  /* Enable I-Cache---------------------------------------------------------*/
  SCB_EnableICache();

  /* Enable D-Cache---------------------------------------------------------*/
  SCB_EnableDCache();

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_USART1_UART_Init();
  MX_ADC1_Init();
  MX_TIM7_Init();
  MX_DAC1_Init();
  MX_TIM15_Init();
  MX_TIM6_Init();
  MX_TIM4_Init();
  /* USER CODE BEGIN 2 */
	//	输出直流电平
//	HAL_DAC_SetValue(&hdac1,DAC_CHANNEL_2,DAC_ALIGN_12B_R,2047-1);	//12bit右对齿
//	HAL_DAC_Start(&hdac1,DAC_CHANNEL_2);	//软件触发

	// 	输出三角波（霿弿启定时器，且在DAC1中?择triangle
//	HAL_TIM_Base_Start(&htim6);//打开定时噿6
//	HAL_DAC_Start(&hdac1,DAC_CHANNEL_2);
	
	//  输出方波	对应DMA中的位长:2
//	SineWave();//生成正弦数据
//	HAL_DAC_Start_DMA(&hdac1,DAC_CHANNEL_2,(uint32_t *)Dat,2,DAC_ALIGN_12B_R);//开启DMA-DAC
//  HAL_TIM_Base_Start(&htim6);//打开定时器6

	//  输出正弦波
		SineWave();//生成正弦数据
		HAL_DAC_Start_DMA(&hdac1,DAC_CHANNEL_1,(uint32_t *)Dat,100,DAC_ALIGN_12B_R);//开启DMA-DAC
		HAL_DAC_Start_DMA(&hdac1,DAC_CHANNEL_2,(uint32_t *)Dat,100,DAC_ALIGN_12B_R);//开启DMA-DAC
//		HAL_TIM_Base_Start(&htim6);//打开定时器4,6，开启屏蔽发生器，灯亮
//		HAL_TIM_Base_Start(&htim4);//PA4	40k,PA5	40.5k
	
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
//		if(adc_times==5)
//		{
//			adc_times=0;
//			if(sound_flag>=2)
//			{
//				sound_flag = 0;
//				HAL_TIM_Base_Start(&htim6);//打开定时器4,6，开启屏蔽发生器，灯亮
//				HAL_TIM_Base_Start(&htim4);//PA4	40k,PA5	40.5k
//				HAL_GPIO_WritePin(pb_LED_GPIO_Port,pb_LED_Pin,GPIO_PIN_SET);
//				printf("Start\n");
//			}
//			else
//			{
//				HAL_TIM_Base_Stop(&htim6);
//				HAL_TIM_Base_Stop(&htim4);
//				HAL_GPIO_WritePin(pb_LED_GPIO_Port,pb_LED_Pin,GPIO_PIN_RESET);
//				printf("Stop\n");
//			}
//		}
//		else
//		{
//			adc_times++;
//		}
//		
//		adc_init();
//		Find_Vpp();
//		FFT_Init();
//		FFT_DIS();
//		if(delta_v > 0.15)
//		{
//			sound_flag+=1;
//		}

		adc_init();
		Find_Vpp();
		if(delta_v > 0.2)
		{
			sound_flag+=1;
			if(sound_flag>2)sound_flag=2;
		}
		else 
		{
			sound_flag-=1;
			if(sound_flag<0)sound_flag=0;
		}
		if(sound_flag==2)
		{
			HAL_TIM_Base_Start(&htim6);//打开定时器4,6，开启屏蔽发生器，灯亮
			HAL_TIM_Base_Start(&htim4);//PA4	40k,PA5	40.5k
			HAL_GPIO_WritePin(pb_LED_GPIO_Port,pb_LED_Pin,GPIO_PIN_SET);
		}
		else if(sound_flag ==0)
		{
			HAL_TIM_Base_Stop(&htim6);
			HAL_TIM_Base_Stop(&htim4);
			HAL_GPIO_WritePin(pb_LED_GPIO_Port,pb_LED_Pin,GPIO_PIN_RESET);
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

/* USER CODE BEGIN 4 */

void Find_Vpp(void)
{
		float voltage = 0;
	
		vi_max = adc1_data[20]*3.3/65535;
		vi_min = adc1_data[20]*3.3/65535;
		for (u16 temp = 400 ;temp < FFT_LENGTH-400 ;temp++)
		{
			voltage = adc1_data[temp]*3.3/65535;	//璁＄畻voltage_real
//			printf("%f\r\n",voltage);
	//		printf("%d\r\n",adc1_data[temp]);
				if(voltage>vi_max)
				{
					vi_max = voltage;
				}
				if(voltage<vi_min)
				{
					vi_min = voltage;
				}
		}
		delta_v = vi_max - vi_min;
//		printf("vi_max = %f\n",vi_max);
//		printf("vi_min = %f\n",vi_min);
//		printf("delta_v = %f\n",delta_v);

}


			//涓柇鍥炶皟鍑芥暟锛岄噰闆嗗畬鎷夐珮鏍囧織浣岮dcConvEnd
void HAL_ADC_ConvCpltCallback(ADC_HandleTypeDef* hadc)
{
   if(hadc->Instance == ADC1) 
	{
      //SCB_InvalidateDCache_by_Addr((uint32_t *) &adc1_data[0], ADC1_BUFFER_SIZE);
   }
	 AdcConvEnd = 1;
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
