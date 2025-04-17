// Fill out your copyright notice in the Description page of Project Settings.


#include "Component/SimpleInputComponent.h"
#include "Components/InputComponent.h"
#include "Player/SimpleEnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "InputActionValue.h"
#include "GameplayTagContainer.h"
#include "Player/SimplePlayerController.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/Controller.h"
#include "SimpleGameplayTags.h"
#include "UserSettings/EnhancedInputUserSettings.h"
#include "Abilities/SimpleAbilitySystemComponent.h"

// Sets default values for this component's properties
USimpleInputComponent::USimpleInputComponent()
{
	// Set this component to be initialized when the game starts, and to be ticked every frame.  You can turn these features
	// off to improve performance if you don't need them.
	PrimaryComponentTick.bCanEverTick = false;
	
	AbilitySystemComponent = nullptr;
}


// Called when the game starts
void USimpleInputComponent::BeginPlay()
{
	Super::BeginPlay();

	// ...
}


// Called every frame
void USimpleInputComponent::TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction)
{
	Super::TickComponent(DeltaTime, TickType, ThisTickFunction);

	// ...
}

void USimpleInputComponent::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	APawn* Pawn = Cast<APawn>(GetOwner());

	if (!Pawn)
	{
		return;
	}

	if (ASimplePlayerController* SimplePlayerController = Pawn->GetController<ASimplePlayerController>())
	{
		if (ULocalPlayer* LocalPlayer = SimplePlayerController->GetLocalPlayer())
		{
			USimpleEnhancedInputComponent* SimpleEnhancedInputComponent = Cast<USimpleEnhancedInputComponent>(PlayerInputComponent);
			if (SimpleEnhancedInputComponent)
			{
				UEnhancedInputLocalPlayerSubsystem* Subsystem = LocalPlayer->GetSubsystem<UEnhancedInputLocalPlayerSubsystem>();

				if (Subsystem)
				{
					Subsystem->ClearAllMappings();
					if (DefaultInputConfig)
					{
						for (const FInputMappingContextAndPriority& Mapping : DefaultInputConfig->DefaultInputMappings)
						{
							if (UInputMappingContext* IMC = Mapping.InputMapping.Get())
							{
								if (Mapping.bRegisterWithSettings)
								{
									if (UEnhancedInputUserSettings* Settings = Subsystem->GetUserSettings())
									{
										Settings->RegisterInputMappingContext(IMC);
									}

									FModifyContextOptions Options = {};
									Options.bIgnoreAllPressedKeysUntilRelease = false;
									Subsystem->AddMappingContext(IMC, Mapping.Priority, Options);
								}
							}
						}

						if (SimpleEnhancedInputComponent)
						{
							TArray<uint32> BindHandles;
							SimpleEnhancedInputComponent->BindAbilityActions(DefaultInputConfig, this, &ThisClass::Input_AbilityInputTagPressed, &ThisClass::Input_AbilityInputTagReleased, /*out*/ BindHandles);

							SimpleEnhancedInputComponent->BindNativeAction(DefaultInputConfig, SimpleGameplayTags::InputTag_Move, ETriggerEvent::Triggered, this, &ThisClass::Input_Move, /*bLogIfNotFound=*/ false);
							SimpleEnhancedInputComponent->BindNativeAction(DefaultInputConfig, SimpleGameplayTags::InputTag_Look_Mouse, ETriggerEvent::Triggered, this, &ThisClass::Input_LookMouse, /*bLogIfNotFound=*/ false);
						}
					}

				}
			}
		}
	}
}

void USimpleInputComponent::Input_AbilityInputTagPressed(FGameplayTag InputTag)
{
	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->AbilityInputTagPressed(InputTag);
	}
}

void USimpleInputComponent::Input_AbilityInputTagReleased(FGameplayTag InputTag)
{
	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->AbilityInputTagReleased(InputTag);
	}
}

void USimpleInputComponent::Input_Move(const FInputActionValue& InputActionValue)
{
	APawn* Pawn = Cast<APawn>(GetOwner());

	if (!Pawn)
	{
		return;
	}

	AController* Controller = Pawn->GetController();

	if (Controller)
	{
		const FVector2D Value = InputActionValue.Get<FVector2D>();
		const FRotator MovementRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);

		if (Value.X != 0.0f)
		{
			const FVector MovementDirection = MovementRotation.RotateVector(FVector::RightVector);
			Pawn->AddMovementInput(MovementDirection, Value.X);
		}

		if (Value.Y != 0.0f)
		{
			const FVector MovementDirection = MovementRotation.RotateVector(FVector::ForwardVector);
			Pawn->AddMovementInput(MovementDirection, Value.Y);
		}
	}
}

void USimpleInputComponent::Input_LookMouse(const FInputActionValue& InputActionValue)
{
	APawn* Pawn = Cast<APawn>(GetOwner());

	if (!Pawn)
	{
		return;
	}


	const FVector2D Value = InputActionValue.Get<FVector2D>();

	if (Value.X != 0.0f)
	{
		Pawn->AddControllerYawInput(Value.X);
	}

	if (Value.Y != 0.0f)
	{
		Pawn->AddControllerPitchInput(Value.Y);
	}
}