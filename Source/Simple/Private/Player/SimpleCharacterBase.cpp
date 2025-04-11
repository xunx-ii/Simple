// Fill out your copyright notice in the Description page of Project Settings.

#include "Player/SimpleCharacterBase.h"
#include "Abilities/SimpleAbilitySystemComponent.h"
#include "Player/SimplePlayerState.h"
#include "Player/SimplePlayerController.h"
#include "Player/SimpleEnhancedInputComponent.h"
#include "EnhancedInputSubsystems.h"
#include "System/SimplePawnData.h"
#include "UserSettings/EnhancedInputUserSettings.h"
#include "InputMappingContext.h"
#include "SimpleGameplayTags.h"
#include "Player/SimpleCharacterMovementComponent.h"
#include "Components/SkeletalMeshComponent.h"
#include "Components/CapsuleComponent.h"


ASimpleCharacterBase::ASimpleCharacterBase(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer.SetDefaultSubobjectClass<USimpleCharacterMovementComponent>(ACharacter::CharacterMovementComponentName))
{
	PrimaryActorTick.bCanEverTick = false;
	PrimaryActorTick.bStartWithTickEnabled = false;

	SetNetCullDistanceSquared(900000000.0f);

	UCapsuleComponent* CapsuleComp = GetCapsuleComponent();
	CapsuleComp->InitCapsuleSize(40.0f, 90.0f);

	USkeletalMeshComponent* SkeletalMeshComponent = GetMesh();
	SkeletalMeshComponent->SetRelativeRotation(FRotator(0.0f, -90.0f, 0.0f));

	USimpleCharacterMovementComponent* SimpleCharacterMovementComponent = CastChecked<USimpleCharacterMovementComponent>(GetCharacterMovement());
	SimpleCharacterMovementComponent->GravityScale = 1.0f;
	SimpleCharacterMovementComponent->MaxAcceleration = 2400.0f;
	SimpleCharacterMovementComponent->BrakingFrictionFactor = 1.0f;
	SimpleCharacterMovementComponent->BrakingFriction = 6.0f;
	SimpleCharacterMovementComponent->GroundFriction = 8.0f;
	SimpleCharacterMovementComponent->BrakingDecelerationWalking = 1400.0f;
	SimpleCharacterMovementComponent->bUseControllerDesiredRotation = false;
	SimpleCharacterMovementComponent->bOrientRotationToMovement = false;
	SimpleCharacterMovementComponent->RotationRate = FRotator(0.0f, 720.0f, 0.0f);
	SimpleCharacterMovementComponent->bAllowPhysicsRotationDuringAnimRootMotion = false;
	SimpleCharacterMovementComponent->GetNavAgentPropertiesRef().bCanCrouch = true;
	SimpleCharacterMovementComponent->bCanWalkOffLedgesWhenCrouching = true;
	SimpleCharacterMovementComponent->SetCrouchedHalfHeight(65.0f);

	bUseControllerRotationPitch = false;
	bUseControllerRotationYaw = true;
	bUseControllerRotationRoll = false;

	BaseEyeHeight = 80.0f;
	CrouchedEyeHeight = 50.0f;

	SetReplicates(true);

	AbilitySystemComponent = nullptr;
}


UAbilitySystemComponent* ASimpleCharacterBase::GetAbilitySystemComponent() const
{
	return AbilitySystemComponent;
}


void ASimpleCharacterBase::PossessedBy(AController* NewController)
{
	Super::PossessedBy(NewController);

	ASimplePlayerState* SimplePlayerState = GetPlayerState<ASimplePlayerState>();
	if (SimplePlayerState)
	{
		InitializeAbilitySystem(SimplePlayerState->GetSimpleAbilitySystemComponent(), this);
	}
}


void ASimpleCharacterBase::OnRep_PlayerState()
{
	Super::OnRep_PlayerState();

	ASimplePlayerState* SimplePlayerState = GetPlayerState<ASimplePlayerState>();
	if (SimplePlayerState)
	{
		InitializeAbilitySystem(SimplePlayerState->GetSimpleAbilitySystemComponent(), this);
	}
}


void ASimpleCharacterBase::BeginPlay()
{
	Super::BeginPlay();

	
}

void ASimpleCharacterBase::UninitializeAbilitySystem()
{
	if (!AbilitySystemComponent)
	{
		return;
	}

	if (AbilitySystemComponent->GetAvatarActor() == this)
	{
		AbilitySystemComponent->DestroyActiveState();
		AbilitySystemComponent->RemoveAllGameplayCues();

		if (AbilitySystemComponent->GetOwnerActor() != nullptr)
		{
			AbilitySystemComponent->SetAvatarActor(nullptr);
		}
		else
		{
			AbilitySystemComponent->ClearActorInfo();
		}
	}

	AbilitySystemComponent = nullptr;
}


void ASimpleCharacterBase::InitializePlayerInput(class UInputComponent* PlayerInputComponent)
{
	if (ASimplePlayerController* SimplePlayerController = GetController<ASimplePlayerController>())
	{
		if (ULocalPlayer* LocalPlayer = SimplePlayerController->GetLocalPlayer())
		{
			USimpleEnhancedInputComponent* SimpleEnhancedInputComponent = Cast<USimpleEnhancedInputComponent>(PlayerInputComponent);
			if (SimpleEnhancedInputComponent)
			{
				UEnhancedInputLocalPlayerSubsystem* Subsystem = LocalPlayer->GetSubsystem<UEnhancedInputLocalPlayerSubsystem>();
				Subsystem->ClearAllMappings();

				if (ASimplePlayerState* SimplePlayerState = GetPlayerState<ASimplePlayerState>())
				{
					const USimplePawnData* SimplePawnData = SimplePlayerState->GetPawnData<USimplePawnData>();
					if (SimplePawnData)
					{
						USimpleInputConfig* SimpleInputConfig = SimplePawnData->InputConfig;
						if (SimpleInputConfig)
						{
							for (const FInputMappingContextAndPriority& Mapping : SimpleInputConfig->DefaultInputMappings)
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
								SimpleEnhancedInputComponent->BindAbilityActions(SimpleInputConfig, this, &ThisClass::Input_AbilityInputTagPressed, &ThisClass::Input_AbilityInputTagReleased, /*out*/ BindHandles);

								SimpleEnhancedInputComponent->BindNativeAction(SimpleInputConfig, SimpleGameplayTags::InputTag_Move, ETriggerEvent::Triggered, this, &ThisClass::Input_Move, /*bLogIfNotFound=*/ false);
								SimpleEnhancedInputComponent->BindNativeAction(SimpleInputConfig, SimpleGameplayTags::InputTag_Look_Mouse, ETriggerEvent::Triggered, this, &ThisClass::Input_LookMouse, /*bLogIfNotFound=*/ false);
							}
						}
					}
				}
			}
		}
	}
}

void ASimpleCharacterBase::InitializeAbilitySystem(USimpleAbilitySystemComponent* InSimpleAbilitySystemComponent, AActor* InOwnerActor)
{
	if (AbilitySystemComponent == InSimpleAbilitySystemComponent)
	{
		return;
	}

	if (AbilitySystemComponent)
	{
		UninitializeAbilitySystem();
	}

	AActor* ExistingAvatar = InSimpleAbilitySystemComponent->GetAvatarActor();

	if ((ExistingAvatar != nullptr) && (ExistingAvatar != this))
	{
		UE_LOG(LogClass, Log, TEXT("Existing avatar (authority=%d)"), ExistingAvatar->HasAuthority() ? 1 : 0);

		ensure(!ExistingAvatar->HasAuthority());

		if (ASimpleCharacterBase* OtherExistingAvatar = Cast<ASimpleCharacterBase>(ExistingAvatar))
		{
			OtherExistingAvatar->UninitializeAbilitySystem();
		}
	}

	AbilitySystemComponent = InSimpleAbilitySystemComponent;
	AbilitySystemComponent->InitAbilityActorInfo(InOwnerActor, this);
}

void ASimpleCharacterBase::Input_Move(const FInputActionValue& InputActionValue)
{
	if (Controller)
	{
		const FVector2D Value = InputActionValue.Get<FVector2D>();
		const FRotator MovementRotation(0.0f, Controller->GetControlRotation().Yaw, 0.0f);

		if (Value.X != 0.0f)
		{
			const FVector MovementDirection = MovementRotation.RotateVector(FVector::RightVector);
			AddMovementInput(MovementDirection, Value.X);
		}

		if (Value.Y != 0.0f)
		{
			const FVector MovementDirection = MovementRotation.RotateVector(FVector::ForwardVector);
			AddMovementInput(MovementDirection, Value.Y);
		}
	}
}

void ASimpleCharacterBase::Input_LookMouse(const FInputActionValue& InputActionValue)
{
	const FVector2D Value = InputActionValue.Get<FVector2D>();

	if (Value.X != 0.0f)
	{
		AddControllerYawInput(Value.X);
	}

	if (Value.Y != 0.0f)
	{
		AddControllerPitchInput(Value.Y);
	}
}

void ASimpleCharacterBase::Input_AbilityInputTagPressed(FGameplayTag InputTag)
{
	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->AbilityInputTagPressed(InputTag);
	}
}


void ASimpleCharacterBase::Input_AbilityInputTagReleased(FGameplayTag InputTag)
{
	if (AbilitySystemComponent)
	{
		AbilitySystemComponent->AbilityInputTagReleased(InputTag);
	}
}

// Called every frame
void ASimpleCharacterBase::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void ASimpleCharacterBase::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

	ASimplePlayerState* SimplePlayerState = GetPlayerState<ASimplePlayerState>();
	if (SimplePlayerState)
	{
		SimplePlayerState->CallOrRegister_OnPawnDataLoaded(FOnSimplePawnDataLoaded::FDelegate::CreateLambda([this, PlayerInputComponent](const USimplePawnData* PawnData)
			{
				this->InitializePlayerInput(PlayerInputComponent);
			}));
	}
	else 
	{
		UE_LOG(LogClass, Error, TEXT("ASimpleCharacterBase::SetupPlayerInputComponent ASimplePlayerState is nullptr!!!!!"));
	}
}

